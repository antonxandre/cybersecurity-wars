import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import helmet from 'helmet';
import cookieParser from 'cookie-parser';
import { AppModule } from './app.module.js';
import { corsOriginCallback } from './common/utils/cors.util.js';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // 1. Security Headers via Helmet (Eixo 1 & OWASP A03 / A07)
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'"],
          styleSrc: ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com'],
          fontSrc: ["'self'", 'https://fonts.gstatic.com'],
          imgSrc: ["'self'", 'data:', 'blob:'],
          connectSrc: ["'self'", 'ws:', 'wss:', 'http:', 'https:'],
        },
      },
      crossOriginEmbedderPolicy: false,
      crossOriginResourcePolicy: { policy: 'cross-origin' },
      frameguard: { action: 'deny' },
      hsts: {
        maxAge: 63072000, // 2 years
        includeSubDomains: true,
        preload: true,
      },
    }),
  );

  // 2. Cookie Parser
  app.use(cookieParser());

  // 3. CORS Configuration
  app.enableCors({
    origin: corsOriginCallback,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  });

  // 4. Global API Prefix
  app.setGlobalPrefix('api', {
    exclude: ['/'],
  });

  // 5. Global Validation Pipe (OWASP A03: strictly reject extra properties & validate types)
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // 6. Graceful Shutdown Hooks
  app.enableShutdownHooks();

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  logger.log(`Cyber Arena API running on http://localhost:${port}/api`);
  logger.log(`WebSocket Gateway active at ws://localhost:${port}/arena`);
}

await bootstrap();
