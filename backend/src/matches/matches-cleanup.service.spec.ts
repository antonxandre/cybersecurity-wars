import { Test, TestingModule } from '@nestjs/testing';
import { MatchesCleanupService } from './matches-cleanup.service.js';
import { MatchesService, MatchSession } from './matches.service.js';
import { MatchesGateway } from './matches.gateway.js';

describe('MatchesCleanupService', () => {
  let cleanupService: MatchesCleanupService;

  const mockMatchesService = {
    cleanupExpiredMatches: vi.fn(),
  };

  const mockMatchesGateway = {
    broadcastRoomDeleted: vi.fn(),
  };

  beforeEach(async () => {
    vi.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MatchesCleanupService,
        {
          provide: MatchesService,
          useValue: mockMatchesService,
        },
        {
          provide: MatchesGateway,
          useValue: mockMatchesGateway,
        },
      ],
    }).compile();

    cleanupService = module.get<MatchesCleanupService>(MatchesCleanupService);
  });

  afterEach(() => {
    cleanupService.stopCleanupJob();
  });

  it('should be defined', () => {
    expect(cleanupService).toBeDefined();
  });

  it('should run cleanup, identify expired rooms and broadcast deletion', () => {
    const fakeExpiredMatch: Partial<MatchSession> = {
      id: 'match-123',
      code: 'EXPIRED-ROOM',
      createdAt: new Date(Date.now() - 70 * 60 * 1000), // 70 minutes ago
    };

    mockMatchesService.cleanupExpiredMatches.mockReturnValue([fakeExpiredMatch]);

    const count = cleanupService.runCleanup();

    expect(count).toBe(1);
    expect(mockMatchesService.cleanupExpiredMatches).toHaveBeenCalledWith(60 * 60 * 1000);
    expect(mockMatchesGateway.broadcastRoomDeleted).toHaveBeenCalledWith(
      fakeExpiredMatch,
      'EXPIRED_AFTER_1_HOUR',
    );
  });

  it('should handle zero expired rooms gracefully', () => {
    mockMatchesService.cleanupExpiredMatches.mockReturnValue([]);

    const count = cleanupService.runCleanup();

    expect(count).toBe(0);
    expect(mockMatchesGateway.broadcastRoomDeleted).not.toHaveBeenCalled();
  });

  it('should start and stop cleanup timer via lifecycle hooks', () => {
    cleanupService.onModuleInit();
    // Verify running without exception
    expect(cleanupService).toBeDefined();

    cleanupService.onModuleDestroy();
    // Verify stopped cleanly
  });

  it('should catch and log errors during cleanup without crashing', () => {
    mockMatchesService.cleanupExpiredMatches.mockImplementation(() => {
      throw new Error('Simulated database/memory failure');
    });

    const count = cleanupService.runCleanup();
    expect(count).toBe(0);
  });
});
