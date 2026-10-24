import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller.js';

describe('AppController', () => {
  let appController: AppController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('should return API banner info', () => {
      const banner = appController.getRoot();
      expect(banner.title).toBe('PromptSec Arena API (CyberWars)');
      expect(banner.status).toBe('online');
      expect(banner.endpoints).toHaveProperty('health');
    });
  });
});
