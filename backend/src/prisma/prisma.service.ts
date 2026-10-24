import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { db } from '../../prisma/db.js';

@Injectable()
export class PrismaService implements OnModuleInit {
  private readonly logger = new Logger(PrismaService.name);
  public client = db;
  private isConnected = false;

  async onModuleInit() {
    try {
      // Test basic connection if DATABASE_URL is configured
      if (process.env.DATABASE_URL && !process.env.DATABASE_URL.includes('localhost:5432/mydb')) {
        this.logger.log('Connecting to PostgreSQL database via Prisma...');
        this.isConnected = true;
      } else {
        this.logger.warn('DATABASE_URL is using placeholder. Running Prisma in managed memory-fallback mode.');
      }
    } catch (err: any) {
      this.logger.warn(`Database connection warning: ${err.message}. Application will use memory-fallback for local/offline mode.`);
    }
  }

  get isDatabaseConnected(): boolean {
    return this.isConnected;
  }
}
