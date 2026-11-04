import { PipeTransform, Injectable, ArgumentMetadata } from '@nestjs/common';

/**
 * Global input sanitization pipe (OWASP A03:2025 - Injection).
 *
 * Applied to HTTP (`body`, `query`, `param`) and WebSocket (`@MessageBody()`) payloads.
 * Framework objects such as the Socket.IO `Socket` (`@ConnectedSocket()`), Express
 * `Request`/`Response` or any other class instance are never traversed: they contain
 * circular references and are not user-controlled input.
 */
@Injectable()
export class SanitizationPipe implements PipeTransform {
  /** Hard limit to protect against deeply nested payloads (DoS). */
  private static readonly MAX_DEPTH = 32;

  /** HTTP param types that carry user-controlled input. */
  private static readonly HTTP_INPUT_TYPES = new Set<unknown>(['body', 'query', 'param']);

  /** `WsParamtype.PAYLOAD` from `@nestjs/websockets` (`@MessageBody()`). */
  private static readonly WS_PAYLOAD_TYPE = 3;

  transform(value: any, metadata?: ArgumentMetadata) {
    if (metadata && !this.isUserInput(metadata)) {
      return value;
    }
    return this.sanitizeValue(value, new WeakSet<object>(), 0);
  }

  private isUserInput(metadata: ArgumentMetadata): boolean {
    const type = metadata.type as unknown;
    return (
      SanitizationPipe.HTTP_INPUT_TYPES.has(type) ||
      type === SanitizationPipe.WS_PAYLOAD_TYPE
    );
  }

  private sanitizeValue(value: any, seen: WeakSet<object>, depth: number): any {
    if (typeof value === 'string') {
      return this.sanitizeString(value);
    }

    if (typeof value !== 'object' || value === null) {
      return value;
    }

    // Only traverse plain JSON-like structures; leave class instances untouched.
    if (!Array.isArray(value) && !this.isPlainObject(value)) {
      return value;
    }

    if (seen.has(value) || depth >= SanitizationPipe.MAX_DEPTH) {
      return value;
    }
    seen.add(value);

    if (Array.isArray(value)) {
      return value.map((item) => this.sanitizeValue(item, seen, depth + 1));
    }

    const sanitized: Record<string, any> = {};
    for (const key of Object.keys(value)) {
      sanitized[key] = this.sanitizeValue(value[key], seen, depth + 1);
    }
    return sanitized;
  }

  private isPlainObject(value: object): boolean {
    const proto = Object.getPrototypeOf(value);
    return proto === Object.prototype || proto === null;
  }

  private sanitizeString(str: string): string {
    return str
      // Trim surrounding whitespace
      .trim()
      // Neutralize potential script tags and basic XSS payload injection
      .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
      // Neutralize LLM special control token injections
      .replace(/<\|endoftext\|>|<\|im_start\|>|<\|im_end\|>/gi, '');
  }
}
