---
name: nestjs-security-owasp
description: Implements OWASP Top 10:2025 security defenses in NestJS, specifically A01 (Broken Access Control & RBAC), A03 (Injection & Prompt Sanitization), and A07 (Authentication Failures, Argon2id, JWT rotation, and Rate Limiting). Use when developing or securing auth flows, endpoints, role guards, password hashing, and input validation.
---

# NestJS Security & OWASP Top 10:2025 Safeguards

This skill defines mandatory security standards and implementation patterns for the PromptSec Arena backend, aligning directly with the project guidelines.

## 1. OWASP A01:2025 - Broken Access Control

### Implementation Patterns:
1. **Role-Based Access Control (RBAC)**:
   - Define user roles: `RED_TEAM`, `BLUE_TEAM`, `CASTER`, `ADMIN`.
   - Use custom decorators (`@Roles('ADMIN', 'BLUE_TEAM')`) and a global or controller-level `RolesGuard`.
2. **Route Guards & JWT Verification**:
   - `AuthGuard` extracts Bearer token or HttpOnly cookie, verifies signature and expiration, and attaches the sanitized `user` object to `request.user`.
   - Deny by default: Any endpoint without `@Public()` decorator requires valid authentication.
3. **Horizontal Privilege Escalation Prevention**:
   - In match actions or prompt edits, verify that the authenticated `user.id` or `user.role` matches the resource owner/team before mutating state.
   ```typescript
   if (match.blueTeamPlayerId !== user.id && user.role !== Role.ADMIN) {
     throw new ForbiddenException('Only the assigned Blue Team player may patch the system prompt.');
   }
   ```

## 2. OWASP A03:2025 - Injection (Prompt & Data Injection)

### Implementation Patterns:
1. **Parameterized Database Queries**:
   - Prisma ORM automatically utilizes parameterized queries, eliminating SQL injection vectors.
2. **Strict DTO Sanitization & Validation**:
   - Reject untrusted inputs with `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true })`.
   - Strip leading/trailing control characters and normalize Unicode.
3. **Prompt Delimiter Isolation & System Prompt Protection**:
   - For LLM interactions, never concatenate raw user input directly into system prompt instructions.
   - Enclose user prompts in explicit delimiters:
     ```typescript
     export function buildDelimitedPrompt(systemPrompt: string, userPrompt: string): string {
       const sanitizedUserPrompt = userPrompt.replace(/<\|endoftext\|>|\[\/?INST\]/gi, '');
       return `${systemPrompt}\n\n<user_input>\n${sanitizedUserPrompt}\n</user_input>`;
     }
     ```
   - Enforce canary token checks and regex scanning on LLM outputs to detect prompt leakage (`FLAG{...}`).

## 3. OWASP A07:2025 - Identification & Authentication Failures

### Implementation Patterns:
1. **State-of-the-Art Password Hashing with Argon2id**:
   - Always hash passwords using Argon2id (`argon2.hash(password, { type: argon2.argon2id })`).
   - Constant-time verification (`argon2.verify(hash, password)`).
2. **Protection Against Brute Force & Account Lockout**:
   - Use `@nestjs/throttler` on sensitive endpoints (e.g. 5 requests per 60 seconds on `/auth/login`).
   - Track failed attempts per IP and account; lock account temporarily after 5 consecutive failures for 15 minutes.
3. **Secure Token Management**:
   - Short-lived Access Tokens (e.g. 15 minutes) and rotated Refresh Tokens stored securely as HttpOnly cookies or hashed in the database.
   - User Enumeration Defense: Authentication failure must always return a generic message (`Invalid email or password`) regardless of whether the account exists.
4. **Logout Session Invalidation**:
   - Invalidate refresh token on the server (`refreshTokenHash: null`) and clear client authentication cookies immediately.

## 4. HTTP Headers & Transport Hardening

- **Helmet**: Enable strict CSP, HSTS (`max-age=63072000; includeSubDomains; preload`), `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`.
- **CORS**: Explicit origin whitelist (no wildcard `*` with credentials).
