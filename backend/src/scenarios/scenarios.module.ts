import { Module } from '@nestjs/common';
import { ScenariosService } from './scenarios.service.js';
import { ScenariosController } from './scenarios.controller.js';

@Module({
  controllers: [ScenariosController],
  providers: [ScenariosService],
  exports: [ScenariosService],
})
export class ScenariosModule {}
