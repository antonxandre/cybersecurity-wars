import { IsNotEmpty, IsString, MaxLength, IsNumber, IsIn } from 'class-validator';

export class SubmitPromptDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(4000)
  prompt: string;
}

export class SubmitPatchDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(4000)
  patchInstruction: string;
}

export class UpdatePortRuleDto {
  @IsNumber()
  port: number;

  @IsString()
  @IsIn(['OPEN', 'RESTRICTED', 'CLOSED', 'HONEYPOT'])
  action: 'OPEN' | 'RESTRICTED' | 'CLOSED' | 'HONEYPOT';
}
