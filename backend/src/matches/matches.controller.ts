import {
  Controller,
  Post,
  Get,
  Delete,
  Param,
  Body,
  UseGuards,
  Req,
  ForbiddenException,
} from '@nestjs/common';
import { MatchesService } from './matches.service.js';
import { MatchesGateway } from './matches.gateway.js';
import { CreateMatchDto } from './dto/create-match.dto.js';
import { SubmitPromptDto, SubmitPatchDto, UpdatePortRuleDto } from './dto/match-action.dto.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { Public } from '../common/decorators/public.decorator.js';
import { UserRole } from '../common/decorators/roles.decorator.js';

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
      role: dto.joinAsTeam ?? UserRole.BLUE_TEAM,
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

  @Delete(':id')
  async delete(@Param('id') id: string, @Req() req: any) {
    const match = await this.matchesService.getMatch(id);
    const username = req.user.username;
    const role = req.user.role;

    const isHost =
      match.hostUsername === username ||
      match.bluePlayer?.username === username ||
      match.redPlayer?.username === username;
    const isAdmin = role === 'ADMIN';

    if (!isHost && !isAdmin) {
      throw new ForbiddenException(
        'Apenas o Host da sala ou um Administrador pode encerrar esta sala (OWASP A01)',
      );
    }

    const deleted = this.matchesService.deleteMatch(id);
    if (deleted) {
      this.matchesGateway.broadcastRoomDeleted(deleted, 'MANUAL_DELETION');
    }
    return { success: true, message: `Sala ${id} encerrada com sucesso.` };
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
