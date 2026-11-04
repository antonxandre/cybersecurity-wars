import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { MatchesService } from './matches.service.js';
import { MatchesGateway } from './matches.gateway.js';

@Injectable()
export class MatchesCleanupService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(MatchesCleanupService.name);
  private timer: NodeJS.Timeout | null = null;

  // Tempo de expiração padrão: 1 hora (3.600.000 ms)
  private readonly roomTtlMs: number;
  // Intervalo de varredura do job: a cada 1 minuto (60.000 ms)
  private readonly intervalMs: number;

  constructor(
    private readonly matchesService: MatchesService,
    private readonly matchesGateway: MatchesGateway,
  ) {
    const envTtl = process.env.ROOM_TTL_MS ? parseInt(process.env.ROOM_TTL_MS, 10) : NaN;
    this.roomTtlMs = !isNaN(envTtl) && envTtl > 0 ? envTtl : 60 * 60 * 1000;

    const envInterval = process.env.ROOM_CLEANUP_INTERVAL_MS
      ? parseInt(process.env.ROOM_CLEANUP_INTERVAL_MS, 10)
      : NaN;
    this.intervalMs = !isNaN(envInterval) && envInterval > 0 ? envInterval : 60 * 1000;
  }

  onModuleInit() {
    this.startCleanupJob();
  }

  onModuleDestroy() {
    this.stopCleanupJob();
  }

  startCleanupJob() {
    if (this.timer) {
      clearInterval(this.timer);
    }

    this.logger.log(
      `Job de limpeza de salas ativado (TTL: ${this.roomTtlMs / 1000 / 60} min, Varredura a cada: ${this.intervalMs / 1000} s)`,
    );

    this.timer = setInterval(() => {
      this.runCleanup();
    }, this.intervalMs);

    if (this.timer && typeof this.timer.unref === 'function') {
      this.timer.unref();
    }
  }

  stopCleanupJob() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
      this.logger.log('Job de limpeza de salas desativado.');
    }
  }

  runCleanup(): number {
    try {
      const expired = this.matchesService.cleanupExpiredMatches(this.roomTtlMs);
      if (expired.length > 0) {
        this.logger.log(
          `[Job Limpeza] ${expired.length} sala(s) criada(s) há mais de 1h excluída(s) com sucesso.`,
        );
        for (const match of expired) {
          this.matchesGateway.broadcastRoomDeleted(match, 'EXPIRED_AFTER_1_HOUR');
        }
      }
      return expired.length;
    } catch (error) {
      this.logger.error(`[Job Limpeza] Erro ao executar varredura de salas: ${String(error)}`);
      return 0;
    }
  }
}
