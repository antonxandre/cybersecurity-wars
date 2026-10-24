import { Test, TestingModule } from '@nestjs/testing';
import { ScenariosService } from './scenarios.service.js';

describe('ScenariosService', () => {
  let service: ScenariosService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ScenariosService],
    }).compile();

    service = module.get<ScenariosService>(ScenariosService);
  });

  it('should list all 4 official game scenarios', async () => {
    const scenarios = await service.getAllScenarios();
    expect(scenarios.length).toBe(4);
    const ids = scenarios.map((s) => s.id);
    expect(ids).toContain('scenario-a');
    expect(ids).toContain('scenario-b');
    expect(ids).toContain('scenario-c');
    expect(ids).toContain('scenario-d');
  });

  it('should return scenario details with presets and port configs', async () => {
    const scenarioB = await service.getScenarioById('scenario-b');
    expect(scenarioB.title).toContain('Hardening');
    expect(scenarioB.initialPorts.some((p) => p.port === 443)).toBe(true);
    expect(scenarioB.recommendedBluePresets.length).toBeGreaterThan(0);
    expect(scenarioB.recommendedRedPresets.length).toBeGreaterThan(0);
  });
});
