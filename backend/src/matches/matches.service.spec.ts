import { Test, TestingModule } from '@nestjs/testing';
import { MatchesService } from './matches.service.js';
import { ScenariosService } from '../scenarios/scenarios.service.js';
import { UserRole } from '../common/decorators/roles.decorator.js';

describe('MatchesService', () => {
  let matchesService: MatchesService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [MatchesService, ScenariosService],
    }).compile();

    matchesService = module.get<MatchesService>(MatchesService);
  });

  it('should be defined', () => {
    expect(matchesService).toBeDefined();
  });

  it('should create a match with initial scenario ports and baseline tension', async () => {
    const user = { sub: 10, username: 'red_hacker', role: UserRole.RED_TEAM };
    const match = await matchesService.createMatch('scenario-b', user);

    expect(match.id).toBeDefined();
    expect(match.scenarioTitle).toContain('Hardening');
    expect(match.redPlayer?.username).toBe('red_hacker');
    expect(match.currentLogprob).toBe(0.12);
    expect(match.systemSla).toBe(100.0);
    expect(match.status).toBe('WAITING');
  });

  it('should transition to IN_PROGRESS when both players join', async () => {
    const red = { sub: 10, username: 'red_hacker', role: UserRole.RED_TEAM };
    const blue = { sub: 20, username: 'blue_defender', role: UserRole.BLUE_TEAM };

    const match = await matchesService.createMatch('scenario-b', red);
    const updated = await matchesService.joinMatch(match.id, blue);

    expect(updated.status).toBe('IN_PROGRESS');
    expect(updated.bluePlayer?.username).toBe('blue_defender');
    expect(updated.events.length).toBeGreaterThan(0);
  });

  it('should penalize SLA if Blue Team closes port 443 (HTTPS)', async () => {
    const red = { sub: 10, username: 'red_hacker', role: UserRole.RED_TEAM };
    const blue = { sub: 20, username: 'blue_defender', role: UserRole.BLUE_TEAM };

    const match = await matchesService.createMatch('scenario-b', red);
    await matchesService.joinMatch(match.id, blue);

    const result = await matchesService.updatePortRule(match.id, blue, 443, 'CLOSED');
    expect(result.match.systemSla).toBe(85.0); // 100 - 15% SLA penalty!
  });
});
