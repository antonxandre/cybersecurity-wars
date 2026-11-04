import { describe, it, expect } from 'vitest';
import { parseAllowedOrigins, isOriginAllowed, corsOriginCallback } from './cors.util.js';

describe('cors.util', () => {
  describe('parseAllowedOrigins', () => {
    it('should return defaults if not defined', () => {
      const origins = parseAllowedOrigins(undefined);
      expect(origins).toEqual([
        'http://localhost:8080',
        'http://127.0.0.1:8080',
        'http://localhost:3000',
      ]);
    });

    it('should clean quotes and split comma-separated origins', () => {
      const origins = parseAllowedOrigins('"http://localhost:8080, http://127.0.0.1:8080 , http://localhost:3000"');
      expect(origins).toEqual([
        'http://localhost:8080',
        'http://127.0.0.1:8080',
        'http://localhost:3000',
      ]);
    });
  });

  describe('isOriginAllowed', () => {
    it('should allow requests with no origin (curl, mobile, server-to-server)', () => {
      expect(isOriginAllowed(undefined)).toBe(true);
    });

    it('should allow wildcard origin if configured', () => {
      expect(isOriginAllowed('https://random-site.com', ['*'], 'production')).toBe(true);
    });

    it('should allow explicitly whitelisted origins', () => {
      expect(
        isOriginAllowed('https://arena.promptsec.com', ['https://arena.promptsec.com'], 'production'),
      ).toBe(true);
    });

    it('should allow any port on localhost / 127.0.0.1 in development (Flutter Web)', () => {
      expect(isOriginAllowed('http://localhost:54321', ['http://localhost:8080'], 'development')).toBe(true);
      expect(isOriginAllowed('http://127.0.0.1:61234', ['http://localhost:8080'], 'development')).toBe(true);
      expect(isOriginAllowed('http://[::1]:52123', ['http://localhost:8080'], 'development')).toBe(true);
    });

    it('should allow dynamic localhost if localhost is explicitly in whitelist even in production', () => {
      expect(
        isOriginAllowed('http://localhost:59999', ['http://localhost:8080'], 'production'),
      ).toBe(true);
    });

    it('should block external untrusted origins in development and production', () => {
      expect(isOriginAllowed('http://evil.com', ['http://localhost:8080'], 'development')).toBe(false);
      expect(isOriginAllowed('http://evil.com', ['https://arena.promptsec.com'], 'production')).toBe(false);
    });

    it('should block unauthorized localhost in production if localhost is not in whitelist', () => {
      expect(
        isOriginAllowed('http://localhost:54321', ['https://arena.promptsec.com'], 'production'),
      ).toBe(false);
    });
  });

  describe('corsOriginCallback', () => {
    it('should call callback with null, true for allowed origin', () => {
      let resultAllow: boolean | undefined;
      corsOriginCallback('http://localhost:3000', (err, allow) => {
        expect(err).toBeNull();
        resultAllow = allow;
      });
      expect(resultAllow).toBe(true);
    });

    it('should call callback with null, false for blocked origin without throwing Error', () => {
      let resultAllow: boolean | undefined;
      let resultErr: Error | null = null;
      corsOriginCallback('http://evil-unauthorized-site.com', (err, allow) => {
        resultErr = err;
        resultAllow = allow;
      });
      expect(resultErr).toBeNull();
      expect(resultAllow).toBe(false);
    });
  });
});
