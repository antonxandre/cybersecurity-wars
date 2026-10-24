import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException, ConflictException } from '@nestjs/common';
import { AuthService } from './auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { UserRole } from '../common/decorators/roles.decorator.js';

describe('AuthService', () => {
  let service: AuthService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: PrismaService,
          useValue: { isDatabaseConnected: false },
        },
        {
          provide: JwtService,
          useValue: {
            signAsync: vi.fn().mockResolvedValue('mock-jwt-token'),
            verifyAsync: vi.fn().mockResolvedValue({ sub: 1, email: 'admin@promptsec.arena', role: 'ADMIN' }),
          },
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should authenticate pre-seeded admin user with correct credentials', async () => {
    const result = await service.login({
      email: 'admin@promptsec.arena',
      password: 'Password123!',
    });

    expect(result).toHaveProperty('accessToken');
    expect(result).toHaveProperty('refreshToken');
    expect(result.user.email).toBe('admin@promptsec.arena');
    expect(result.user.role).toBe(UserRole.ADMIN);
  });

  it('should reject invalid password with generic error (OWASP A07)', async () => {
    await expect(
      service.login({
        email: 'admin@promptsec.arena',
        password: 'WrongPassword!',
      }),
    ).rejects.toThrow(UnauthorizedException);
  });

  it('should register a new user with Argon2id hashed password', async () => {
    const result = await service.register({
      email: 'newplayer@promptsec.arena',
      username: 'new_operator',
      password: 'StrongPassword123!',
      role: UserRole.RED_TEAM,
    });

    expect(result.user.username).toBe('new_operator');
    expect(result.user.role).toBe(UserRole.RED_TEAM);
    expect(result).not.toHaveProperty('passwordHash'); // Never expose hash (OWASP A07)
  });

  it('should prevent registration with duplicate email (ConflictException)', async () => {
    await expect(
      service.register({
        email: 'admin@promptsec.arena',
        username: 'another_admin',
        password: 'Password123!',
      }),
    ).rejects.toThrow(ConflictException);
  });
});
