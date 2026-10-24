import {
  Controller,
  Post,
  Get,
  Param,
  Body,
  UseGuards,
  Req,
} from '@nestjs/common';
import { MatchesService } from './matches.service.js';
import { CreateMatchDto } from './dto/create-match.dto.js';
import { SubmitPromptDto, SubmitPatchDto, UpdatePortRuleDto } from './dto/match-action.dto.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';

@Controller('matches')
@UseGuards(JwtAuthGuard)
export class MatchesController {
  constructor(private readonly matchesService: MatchesService) {}

  @Post()
  async create(@Req() req: any, @Body() dto: CreateMatchDto) {
    const user = {
      sub: req.user.sub,
      username: req.user.username,
      role: dto.joinAsTeam ?? req.user.role,
    };
    return this.matchesService.createMatch(dto.scenarioId, user);
  }

  @Get()
  async list() {
    return this.matchesService.getAllMatches();
  }

  @Get(':id')
  async getOne(@Param('id') id: string) {
    return this.matchesService.getMatch(id);
  }

  @Post(':id/join')
  async join(@Param('id') id: string, @Req() req: any, @Body() body: { team?: any }) {
    const user = {
      sub: req.user.sub,
      username: req.user.username,
      role: req.user.role,
    };
    return this.matchesService.joinMatch(id, user, body?.team);
  }

  @Post(':id/prompt')
  async submitPrompt(@Param('id') id: string, @Req() req: any, @Body() dto: SubmitPromptDto) {
    const user = {
      sub: req.user.sub,
      username: req.user.username,
      role: req.user.role,
    };
    return this.matchesService.submitPromptAttack(id, user, dto.prompt);
  }

  @Post(':id/patch')
  async submitPatch(@Param('id') id: string, @Req() req: any, @Body() dto: SubmitPatchDto) {
    const user = {
      sub: req.user.sub,
      username: req.user.username,
      role: req.user.role,
    };
    return this.matchesService.submitSystemPatch(id, user, dto.patchInstruction);
  }

  @Post(':id/ports')
  async updatePort(@Param('id') id: string, @Req() req: any, @Body() dto: UpdatePortRuleDto) {
    const user = {
      sub: req.user.sub,
      username: req.user.username,
      role: req.user.role,
    };
    return this.matchesService.updatePortRule(id, user, dto.port, dto.action);
  }
}
