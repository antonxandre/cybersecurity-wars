import { PipeTransform, Injectable, ArgumentMetadata } from '@nestjs/common';

@Injectable()
export class SanitizationPipe implements PipeTransform {
  transform(value: any, _metadata?: ArgumentMetadata) {
    if (typeof value === 'string') {
      return this.sanitizeString(value);
    }

    if (typeof value === 'object' && value !== null) {
      return this.sanitizeObject(value);
    }

    return value;
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

  private sanitizeObject(obj: any): any {
    if (Array.isArray(obj)) {
      return obj.map((item) => this.transform(item, {} as ArgumentMetadata));
    }

    const sanitized: Record<string, any> = {};
    for (const key of Object.keys(obj)) {
      sanitized[key] = this.transform(obj[key], {} as ArgumentMetadata);
    }
    return sanitized;
  }
}
