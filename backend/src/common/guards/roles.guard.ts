import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY, UserRole } from '../decorators/roles.decorator.js';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    let user: any;
    if (context.getType() === 'ws') {
      const client = context.switchToWs().getClient();
      user = client?.data?.user;
    } else {
      const request = context.switchToHttp().getRequest();
      user = request?.user;
    }

    if (!user || !user.role) {
      throw new ForbiddenException('Access denied: Authentication and specific role required (OWASP A01)');
    }

    // ADMIN has full access across all operations
    if (user.role === UserRole.ADMIN) {
      return true;
    }

    const hasRole = requiredRoles.includes(user.role);
    if (!hasRole) {
      throw new ForbiddenException(`Access denied: Requires role [${requiredRoles.join(', ')}], current role is [${user.role}]`);
    }

    return true;
  }
}
