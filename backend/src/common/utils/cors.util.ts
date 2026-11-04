/**
 * Utility for CORS origin validation in Cyber Arena.
 * Supports:
 * - Direct whitelist matching
 * - Wildcard '*'
 * - Dynamic localhost / 127.0.0.1 ports during local testing & development (Flutter Web, Vite, etc.)
 * - Safe rejection without throwing unhandled exceptions
 */

export function parseAllowedOrigins(corsOriginEnv?: string): string[] {
  const raw = corsOriginEnv ?? process.env.CORS_ORIGIN;
  if (!raw) {
    return ['http://localhost:8080', 'http://127.0.0.1:8080', 'http://localhost:3000'];
  }

  // Remove surrounding quotes if present (e.g. from .env file)
  const cleaned = raw.replace(/^["']|["']$/g, '');
  const origins = cleaned
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

  return origins.length > 0
    ? origins
    : ['http://localhost:8080', 'http://127.0.0.1:8080', 'http://localhost:3000'];
}

export function isOriginAllowed(
  origin: string | undefined,
  envOrigins?: string[],
  nodeEnv?: string,
): boolean {
  // Allow requests with no origin (e.g. mobile apps, curl, Postman, server-to-server)
  if (!origin) {
    return true;
  }

  const allowedOrigins = envOrigins ?? parseAllowedOrigins();
  const currentEnv = nodeEnv ?? process.env.NODE_ENV;

  // Wildcard allows everything
  if (allowedOrigins.includes('*')) {
    return true;
  }

  // Exact match in whitelist
  if (allowedOrigins.includes(origin)) {
    return true;
  }

  // Localhost / loopback check (e.g. Flutter Web on dynamic ports: http://localhost:54321)
  const isLocalhost = /^https?:\/\/(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$/.test(origin);
  const isDev = currentEnv !== 'production';
  const hasLocalhostInWhitelist = allowedOrigins.some(
    (o) => o.includes('localhost') || o.includes('127.0.0.1'),
  );

  if (isLocalhost && (isDev || hasLocalhostInWhitelist)) {
    return true;
  }

  return false;
}

export function corsOriginCallback(
  origin: string | undefined,
  callback: (err: Error | null, allow?: boolean) => void,
): void {
  if (isOriginAllowed(origin)) {
    callback(null, true);
  } else {
    // Return false instead of an Error to prevent Express/NestJS from raising an unhandled 500 error
    callback(null, false);
  }
}
