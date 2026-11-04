import { describe, it, expect, vi, beforeEach } from 'vitest';
import { JwtAuthGuard } from './jwt-auth.guard.js';
import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';

describe('JwtAuthGuard', () => {
  let guard: JwtAuthGuard;
  let jwtService: JwtService;
  let reflector: Reflector;

  beforeEach(() => {
    jwtService = {
      verifyAsync: vi.fn(),
    } as unknown as JwtService;

    reflector = {
      getAllAndOverride: vi.fn().mockReturnValue(false),
    } as unknown as Reflector;

    guard = new JwtAuthGuard(jwtService, reflector);
  });

  describe('WebSocket context (getType() === "ws")', () => {
    it('should allow WebSocket client that already has user populated in data', async () => {
      const mockClient = {
        data: {
          user: { sub: 1, username: 'testuser', role: 'BLUE_TEAM' },
        },
      };

      const mockContext = {
        getHandler: vi.fn(),
        getClass: vi.fn(),
        getType: vi.fn().mockReturnValue('ws'),
        switchToWs: vi.fn().mockReturnValue({
          getClient: () => mockClient,
        }),
        switchToHttp: vi.fn().mockReturnValue({
          getRequest: () => undefined,
        }),
      } as unknown as ExecutionContext;

      const result = await guard.canActivate(mockContext);
      expect(result).toBe(true);
    });

    it('should authenticate WebSocket client using handshake.auth.token if data.user is missing', async () => {
      const mockClient = {
        data: {},
        handshake: {
          auth: { token: 'valid.jwt.token' },
        },
      };

      (jwtService.verifyAsync as any).mockResolvedValue({
        sub: 2,
        username: 'alice',
        role: 'RED_TEAM',
      });

      const mockContext = {
        getHandler: vi.fn(),
        getClass: vi.fn(),
        getType: vi.fn().mockReturnValue('ws'),
        switchToWs: vi.fn().mockReturnValue({
          getClient: () => mockClient,
        }),
      } as unknown as ExecutionContext;

      const result = await guard.canActivate(mockContext);
      expect(result).toBe(true);
      expect(mockClient.data.user).toEqual({
        sub: 2,
        username: 'alice',
        role: 'RED_TEAM',
      });
    });

    it('should assign anonymous caster if WebSocket has no token and allow pass through', async () => {
      const mockClient = {
        data: {},
        handshake: {},
      };

      const mockContext = {
        getHandler: vi.fn(),
        getClass: vi.fn(),
        getType: vi.fn().mockReturnValue('ws'),
        switchToWs: vi.fn().mockReturnValue({
          getClient: () => mockClient,
        }),
      } as unknown as ExecutionContext;

      const result = await guard.canActivate(mockContext);
      expect(result).toBe(true);
      expect(mockClient.data.user).toEqual({
        sub: 0,
        username: 'anonymous_caster',
        role: 'CASTER',
      });
    });
  });

  describe('HTTP context', () => {
    it('should verify Bearer token from HTTP Authorization header', async () => {
      const mockRequest = {
        headers: {
          authorization: 'Bearer valid.jwt.token',
        },
      };

      (jwtService.verifyAsync as any).mockResolvedValue({
        sub: 10,
        username: 'bob',
        role: 'ADMIN',
      });

      const mockContext = {
        getHandler: vi.fn(),
        getClass: vi.fn(),
        getType: vi.fn().mockReturnValue('http'),
        switchToHttp: vi.fn().mockReturnValue({
          getRequest: () => mockRequest,
        }),
      } as unknown as ExecutionContext;

      const result = await guard.canActivate(mockContext);
      expect(result).toBe(true);
      expect((mockRequest as any).user).toEqual({
        sub: 10,
        username: 'bob',
        role: 'ADMIN',
      });
    });

    it('should throw UnauthorizedException when no Authorization header in HTTP request', async () => {
      const mockRequest = {
        headers: {},
      };

      const mockContext = {
        getHandler: vi.fn(),
        getClass: vi.fn(),
        getType: vi.fn().mockReturnValue('http'),
        switchToHttp: vi.fn().mockReturnValue({
          getRequest: () => mockRequest,
        }),
      } as unknown as ExecutionContext;

      await expect(guard.canActivate(mockContext)).rejects.toThrow(UnauthorizedException);
    });
  });
});
