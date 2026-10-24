import { IsEmail, IsNotEmpty, IsString, MinLength, MaxLength, IsEnum, IsOptional } from 'class-validator';
import { UserRole } from '../../common/decorators/roles.decorator.js';

export class RegisterDto {
  @IsEmail({}, { message: 'Must be a valid email address' })
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(3, { message: 'Username must have at least 3 characters' })
  @MaxLength(30, { message: 'Username cannot exceed 30 characters' })
  username: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(8, { message: 'Password must have at least 8 characters' })
  @MaxLength(128, { message: 'Password cannot exceed 128 characters' })
  password: string;

  @IsOptional()
  @IsEnum(UserRole, { message: 'Role must be RED_TEAM, BLUE_TEAM, CASTER, or ADMIN' })
  role?: UserRole;
}
