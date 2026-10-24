import { IsNotEmpty, IsString, IsOptional, IsEnum } from 'class-validator';
import { UserRole } from '../../common/decorators/roles.decorator.js';

export class CreateMatchDto {
  @IsString()
  @IsNotEmpty()
  scenarioId: string;

  @IsOptional()
  @IsEnum(UserRole)
  joinAsTeam?: UserRole;
}
