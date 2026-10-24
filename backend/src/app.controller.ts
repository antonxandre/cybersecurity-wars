import { Controller, Get } from '@nestjs/common';
import { Public } from './common/decorators/public.decorator.js';

@Controller()
export class AppController {
  @Public()
  @Get()
  getRoot() {
    return {
      title: 'PromptSec Arena API (CyberWars)',
      version: '1.0.0',
      description: 'Plataforma gamificada de Capture The Flag para Segurança de LLMs e Redes',
      endpoints: {
        health: '/api/health',
        auth: '/api/auth',
        scenarios: '/api/scenarios',
        matches: '/api/matches',
        users: '/api/users',
        websocket: '/arena',
      },
      status: 'online',
    };
  }
}
