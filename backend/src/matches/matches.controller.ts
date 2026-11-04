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
import { MatchesGateway } from './matches.gateway.js';
import { CreateMatchDto } from './dto/create-match.dto.js';
import { SubmitPromptDto, SubmitPatchDto, UpdatePortRuleDto } from './dto/match-action.dto.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { Public } from '../common/decorators/public.decorator.js';

@Controller('matches')
@UseGuards(JwtAuthGuard)
export class MatchesController {
  constructor(
    private readonly matchesService: MatchesService,
    private readonly matchesGateway: MatchesGateway,
  ) {}

  @Post()
  async create(@Req() req: any, @Body() dto: CreateMatchDto) {
    const user = {
      sub: req.user.sub,
      username: req.user.username,
      role: dto.joinAsTeam ?? req.user.role,
    };
    const match = await this.matchesService.createMatch(dto.scenarioId, user, {
      customCode: dto.customCode,
      is2v2: dto.is2v2,
      mode: dto.mode,
    });
    this.matchesGateway.broadcastRoomCreated(match);
    return match;
  }

  @Get()
  @Public()
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
    const match = await this.matchesService.joinMatch(id, user, body?.team);
    this.matchesGateway.broadcastRoomUpdated(match);
    return match;
  }

  @Post(':id/start')
  async start(@Param('id') id: string, @Req() req: any) {
    const user = {
      sub: req.user.sub,
      username: req.user.username,
      role: req.user.role,
    };
    const match = await this.matchesService.startMatch(id, user);
    this.matchesGateway.broadcastMatchStarted(id, match);
    return match;
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
