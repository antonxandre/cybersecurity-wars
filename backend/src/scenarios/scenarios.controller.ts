import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ScenariosService } from './scenarios.service.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { Public } from '../common/decorators/public.decorator.js';

@Controller('scenarios')
@UseGuards(JwtAuthGuard)
export class ScenariosController {
  constructor(private readonly scenariosService: ScenariosService) {}

  @Public()
  @Get()
  async getAll() {
    return this.scenariosService.getAllScenarios();
  }

  @Public()
  @Get(':id')
  async getOne(@Param('id') id: string) {
    return this.scenariosService.getScenarioById(id);
  }
}
