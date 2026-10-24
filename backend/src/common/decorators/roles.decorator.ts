import { SetMetadata } from '@nestjs/common';

export enum UserRole {
  RED_TEAM = 'RED_TEAM',
  BLUE_TEAM = 'BLUE_TEAM',
  CASTER = 'CASTER',
  ADMIN = 'ADMIN',
}

export const ROLES_KEY = 'roles';
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES_KEY, roles);
