import { Controller, Get } from '@nestjs/common';
import { Public } from '../common/decorators/public.decorator.js';
import { PrismaService } from '../prisma/prisma.service.js';

@Controller('health')
export class HealthController {
  private readonly startTime = Date.now();

  constructor(private readonly prisma: PrismaService) {}

  @Public()
  @Get()
  check() {
    return {
      status: 'ok',
      service: 'promptsec-arena-backend',
      timestamp: new Date().toISOString(),
      uptimeSeconds: Math.floor((Date.now() - this.startTime) / 1000),
      database: this.prisma.isDatabaseConnected ? 'connected' : 'memory_fallback',
      version: '1.0.0',
    };
  }
}
