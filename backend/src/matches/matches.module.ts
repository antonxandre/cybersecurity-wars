import { Module } from '@nestjs/common';
import { MatchesService } from './matches.service.js';
import { MatchesController } from './matches.controller.js';
import { MatchesGateway } from './matches.gateway.js';
import { ScenariosModule } from '../scenarios/scenarios.module.js';

@Module({
  imports: [ScenariosModule],
  controllers: [MatchesController],
  providers: [MatchesService, MatchesGateway],
  exports: [MatchesService, MatchesGateway],
})
export class MatchesModule {}
