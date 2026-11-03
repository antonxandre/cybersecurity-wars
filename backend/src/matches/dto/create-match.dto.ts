import { IsString, IsOptional, IsEnum, IsBoolean } from 'class-validator';
import { UserRole } from '../../common/decorators/roles.decorator.js';

export class CreateMatchDto {
  @IsString()
  @IsOptional()
  scenarioId?: string;

  @IsOptional()
  @IsEnum(UserRole)
  joinAsTeam?: UserRole;

  @IsOptional()
  @IsString()
  customCode?: string;

  @IsOptional()
  @IsBoolean()
  is2v2?: boolean;

  @IsOptional()
  @IsString()
  mode?: string;
}
