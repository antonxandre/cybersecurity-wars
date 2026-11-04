import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException, ConflictException } from '@nestjs/common';
import { validate } from 'class-validator';
import { AuthService } from './auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { UserRole } from '../common/decorators/roles.decorator.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';

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

  describe('Password Security Policy (OWASP A07)', () => {
    it('should pass RegisterDto validation with strong password', async () => {
      const dto = new RegisterDto();
      dto.email = 'valid@promptsec.arena';
      dto.username = 'valid_user';
      dto.password = 'StrongP@ssw0rd!';
      dto.role = UserRole.RED_TEAM;

      const errors = await validate(dto);
      expect(errors.length).toBe(0);

      const userDto = new RegisterDto();
      userDto.email = 'antonio@promptsec.arena';
      userDto.username = 'antonio_op';
      userDto.password = 'Antonio@2092!';
      userDto.role = UserRole.RED_TEAM;

      const userErrors = await validate(userDto);
      expect(userErrors.length).toBe(0);
    });

    it('should reject RegisterDto passwords lacking complexity (symbols, numbers, uppercase, length)', async () => {
      const testCases = [
        'short1!', // < 8 characters
        'alllowercase123!', // no uppercase
        'ALLUPPERCASE123!', // no lowercase
        'NoNumbersHere!', // no number
        'NoSpecialCharacters123', // no symbol
      ];

      for (const pwd of testCases) {
        const dto = new RegisterDto();
        dto.email = 'test@promptsec.arena';
        dto.username = 'test_user';
        dto.password = pwd;

        const errors = await validate(dto);
        const passwordError = errors.find((e) => e.property === 'password');
        expect(passwordError).toBeDefined();
      }
    });

    it('should reject LoginDto passwords that are shorter than 8 characters or exceed 128', async () => {
      const shortLogin = new LoginDto();
      shortLogin.email = 'test@promptsec.arena';
      shortLogin.password = '1234';

      const shortErrors = await validate(shortLogin);
      expect(shortErrors.find((e) => e.property === 'password')).toBeDefined();

      const longLogin = new LoginDto();
      longLogin.email = 'test@promptsec.arena';
      longLogin.password = 'A'.repeat(129);

      const longErrors = await validate(longLogin);
      expect(longErrors.find((e) => e.property === 'password')).toBeDefined();
    });
  });
});

