import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { IS_PUBLIC_KEY } from '../../common/decorators/public.decorator.js';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    // Handle WebSocket context (Socket.IO gateways)
    if (context.getType() === 'ws') {
      return this.handleWsAuth(context);
    }

    const request = context.switchToHttp().getRequest();
    if (!request) {
      return true;
    }

    const token = this.extractTokenFromHeader(request);

    if (!token) {
      throw new UnauthorizedException('Authentication token missing (OWASP A01 / A07)');
    }

    try {
      const payload = await this.jwtService.verifyAsync(token, {
        secret: process.env.JWT_ACCESS_SECRET || 'promptsec-arena-access-secret-key-32chars',
      });
      request.user = payload;
    } catch {
      throw new UnauthorizedException('Invalid or expired authentication token (OWASP A07)');
    }

    return true;
  }

  private async handleWsAuth(context: ExecutionContext): Promise<boolean> {
    const client = context.switchToWs().getClient();
    if (!client) {
      return true;
    }

    // Client authenticated during Socket.IO connection handshake
    if (client.data?.user) {
      return true;
    }

    // Extract token if not already parsed on socket data
    const token = this.extractTokenFromWs(client);
    if (token) {
      try {
        const payload = await this.jwtService.verifyAsync(token, {
          secret: process.env.JWT_ACCESS_SECRET || 'promptsec-arena-access-secret-key-32chars',
        });
        client.data = client.data || {};
        client.data.user = payload;
        return true;
      } catch {
        throw new UnauthorizedException('Invalid or expired WebSocket authentication token (OWASP A07)');
      }
    }

    // Fallback: anonymous caster mode for spectators
    client.data = client.data || {};
    client.data.user = { sub: 0, username: 'anonymous_caster', role: 'CASTER' };
    return true;
  }

  private extractTokenFromWs(client: any): string | undefined {
    if (!client) return undefined;

    if (client.handshake?.auth?.token) {
      return client.handshake.auth.token;
    }

    const authHeader = client.handshake?.headers?.authorization;
    if (authHeader && typeof authHeader === 'string') {
      const [type, token] = authHeader.split(' ');
      if (type === 'Bearer' && token) {
        return token;
      }
      return authHeader;
    }

    if (client.handshake?.query?.token) {
      return client.handshake.query.token as string;
    }

    return undefined;
  }

  private extractTokenFromHeader(request: any): string | undefined {
    if (!request || !request.headers) {
      return undefined;
    }
    const authHeader = request.headers.authorization;
    if (typeof authHeader === 'string') {
      const [type, token] = authHeader.split(' ');
      if (type === 'Bearer' && token) {
        return token;
      }
    }
    // Also support reading from secure cookie if available
    if (request.cookies?.access_token) {
      return request.cookies.access_token;
    }
    return undefined;
  }
}
