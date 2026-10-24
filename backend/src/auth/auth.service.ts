import {
  Injectable,
  OnModuleInit,
  UnauthorizedException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { PrismaService } from '../prisma/prisma.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { UserRole } from '../common/decorators/roles.decorator.js';

export interface UserRecord {
  id: number;
  email: string;
  username: string;
  passwordHash: string;
  role: UserRole;
  failedAttempts: number;
  lockedUntil?: Date | null;
  refreshTokenHash?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class AuthService implements OnModuleInit {
  private readonly logger = new Logger(AuthService.name);
  private readonly MAX_FAILED_ATTEMPTS = 5;
  private readonly LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 minutes

  // In-memory user store fallback for local / offline / test mode
  private memoryUsers: Map<string, UserRecord> = new Map();
  private userCounter = 1;
  private seedPromise: Promise<void>;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {
    this.seedPromise = this.seedDefaultUsers();
  }

  async onModuleInit() {
    await this.seedPromise;
  }

  public async ensureSeeded() {
    await this.seedPromise;
  }

  private async seedDefaultUsers() {
    // Seed default admin and players for immediate testing
    const defaultPassword = 'Password123!';
    const hash = await argon2.hash(defaultPassword, { type: argon2.argon2id });

    const adminUser: UserRecord = {
      id: this.userCounter++,
      email: 'admin@promptsec.arena',
      username: 'admin',
      passwordHash: hash,
      role: UserRole.ADMIN,
      failedAttempts: 0,
      lockedUntil: null,
      refreshTokenHash: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.memoryUsers.set(adminUser.email, adminUser);

    const redUser: UserRecord = {
      id: this.userCounter++,
      email: 'red@promptsec.arena',
      username: 'pyromancer_red',
      passwordHash: hash,
      role: UserRole.RED_TEAM,
      failedAttempts: 0,
      lockedUntil: null,
      refreshTokenHash: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.memoryUsers.set(redUser.email, redUser);

    const blueUser: UserRecord = {
      id: this.userCounter++,
      email: 'blue@promptsec.arena',
      username: 'architect_blue',
      passwordHash: hash,
      role: UserRole.BLUE_TEAM,
      failedAttempts: 0,
      lockedUntil: null,
      refreshTokenHash: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.memoryUsers.set(blueUser.email, blueUser);
  }

  async register(dto: RegisterDto) {
    await this.ensureSeeded();
    // Check if email or username already exists
    for (const u of this.memoryUsers.values()) {
      if (u.email === dto.email) {
        throw new ConflictException('An account with this email address already exists');
      }
      if (u.username === dto.username) {
        throw new ConflictException('Username is already taken');
      }
    }

    // Hash password with Argon2id (OWASP A07)
    const passwordHash = await argon2.hash(dto.password, {
      type: argon2.argon2id,
      memoryCost: 2 ** 16,
      timeCost: 3,
      parallelism: 1,
    });

    const user: UserRecord = {
      id: this.userCounter++,
      email: dto.email,
      username: dto.username,
      passwordHash,
      role: dto.role ?? UserRole.RED_TEAM,
      failedAttempts: 0,
      lockedUntil: null,
      refreshTokenHash: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    this.memoryUsers.set(user.email, user);
    this.logger.log(`New user registered: ${user.username} (${user.role})`);

    const tokens = await this.generateTokens(user);
    return {
      user: this.sanitizeUser(user),
      ...tokens,
    };
  }

  async login(dto: LoginDto, ipAddress: string = '127.0.0.1') {
    await this.ensureSeeded();
    const user = this.memoryUsers.get(dto.email);

    // Defense against user enumeration (OWASP A07): Always perform hash verification or constant time work
    if (!user) {
      await argon2.verify(
        '$argon2id$v=19$m=65536,t=3,p=1$fakeSaltForTimingDeterrent$fakeHash',
        dto.password,
      ).catch(() => false);
      throw new UnauthorizedException('Invalid email or password');
    }

    // Check account lockout
    if (user.lockedUntil && user.lockedUntil.getTime() > Date.now()) {
      const minutesRemaining = Math.ceil((user.lockedUntil.getTime() - Date.now()) / (60 * 1000));
      throw new UnauthorizedException(
        `Account temporarily locked due to excessive failed attempts. Please try again in ${minutesRemaining} minutes. (OWASP A07)`,
      );
    }

    // Verify password with Argon2id
    const isValid = await argon2.verify(user.passwordHash, dto.password);
    if (!isValid) {
      user.failedAttempts += 1;
      if (user.failedAttempts >= this.MAX_FAILED_ATTEMPTS) {
        user.lockedUntil = new Date(Date.now() + this.LOCKOUT_DURATION_MS);
        this.logger.warn(`Account ${user.email} locked out after ${user.failedAttempts} failed attempts from IP ${ipAddress}`);
      }
      throw new UnauthorizedException('Invalid email or password');
    }

    // Reset failed attempts on successful login
    user.failedAttempts = 0;
    user.lockedUntil = null;

    const tokens = await this.generateTokens(user);
    user.refreshTokenHash = await argon2.hash(tokens.refreshToken, { type: argon2.argon2id });
    user.updatedAt = new Date();

    return {
      user: this.sanitizeUser(user),
      ...tokens,
    };
  }

  async refreshTokens(refreshToken: string) {
    try {
      const payload = await this.jwtService.verifyAsync(refreshToken, {
        secret: process.env.JWT_REFRESH_SECRET || 'promptsec-arena-refresh-secret-key-32chars',
      });

      const user = Array.from(this.memoryUsers.values()).find((u) => u.id === payload.sub);
      if (!user || !user.refreshTokenHash) {
        throw new UnauthorizedException('Invalid refresh token session');
      }

      const isValid = await argon2.verify(user.refreshTokenHash, refreshToken);
      if (!isValid) {
        // Suspected token reuse / compromise! Revoke all tokens (OWASP A07)
        user.refreshTokenHash = null;
        throw new UnauthorizedException('Refresh token reuse detected. Please log in again.');
      }

      const tokens = await this.generateTokens(user);
      user.refreshTokenHash = await argon2.hash(tokens.refreshToken, { type: argon2.argon2id });
      return tokens;
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
  }

  async logout(userId: number) {
    const user = Array.from(this.memoryUsers.values()).find((u) => u.id === userId);
    if (user) {
      user.refreshTokenHash = null;
      user.updatedAt = new Date();
    }
    return { success: true, message: 'Logged out successfully (session invalidated)' };
  }

  async findById(userId: number): Promise<UserRecord | null> {
    const user = Array.from(this.memoryUsers.values()).find((u) => u.id === userId);
    return user ?? null;
  }

  public sanitizeUser(user: UserRecord) {
    const { passwordHash: _passwordHash, refreshTokenHash: _refreshTokenHash, ...sanitized } = user;
    return sanitized;
  }

  private async generateTokens(user: UserRecord) {
    const payload = {
      sub: user.id,
      email: user.email,
      username: user.username,
      role: user.role,
    };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: process.env.JWT_ACCESS_SECRET || 'promptsec-arena-access-secret-key-32chars',
        expiresIn: '15m',
      }),
      this.jwtService.signAsync(payload, {
        secret: process.env.JWT_REFRESH_SECRET || 'promptsec-arena-refresh-secret-key-32chars',
        expiresIn: '7d',
      }),
    ]);

    return {
      accessToken,
      refreshToken,
      expiresIn: 900, // 15 minutes in seconds
    };
  }
}
