import {
  IsEmail,
  IsNotEmpty,
  IsString,
  MinLength,
  MaxLength,
  IsEnum,
  IsOptional,
  Matches,
} from 'class-validator';
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
  @Matches(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?~`]).{8,128}$/,
    {
      message:
        'Password must contain at least 1 uppercase letter, 1 lowercase letter, 1 number, and 1 special character (!@#$%^&*)',
    },
  )
  password: string;

  @IsOptional()
  @IsEnum(UserRole, { message: 'Role must be RED_TEAM, BLUE_TEAM, CASTER, or ADMIN' })
  role?: UserRole;
}
