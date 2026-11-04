import { Module } from '@nestjs/common';
import { MatchesService } from './matches.service.js';
import { MatchesController } from './matches.controller.js';
import { MatchesGateway } from './matches.gateway.js';
import { MatchesCleanupService } from './matches-cleanup.service.js';
import { ScenariosModule } from '../scenarios/scenarios.module.js';

@Module({
  imports: [ScenariosModule],
  controllers: [MatchesController],
  providers: [MatchesService, MatchesGateway, MatchesCleanupService],
  exports: [MatchesService, MatchesGateway, MatchesCleanupService],
})
export class MatchesModule {}
