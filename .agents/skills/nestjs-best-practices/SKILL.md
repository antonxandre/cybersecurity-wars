---
name: nestjs-best-practices
description: Architecture, dependency injection, feature modules, DTO validation, error handling, and ESM best practices for NestJS 11+ and 12+. Use when creating, refactoring, or reviewing NestJS modules, controllers, providers, guards, or services.
---

# NestJS Best Practices & Architecture Guide

This skill guides development of scalable, secure, and maintainable NestJS applications in modern ESM and TypeScript environments.

## 1. Architectural Principles

1. **Modular Domain-Driven Design**:
   - Organize by domain feature (`auth`, `users`, `scenarios`, `matches`, `health`).
   - Each module must encapsulate its controllers, services, and repositories, exposing only what consumers need via `exports`.
   - Never import controllers from another module; only import modules that export the required providers.

2. **Constructor Dependency Injection**:
   - Inject dependencies via `constructor(private readonly service: ServiceName) {}`.
   - Avoid Service Locator patterns or direct class instantiations (`new Service()`).

3. **Strict Separation of Concerns**:
   - **Controllers**: Responsible strictly for HTTP routing, parameter extraction (`@Param()`, `@Body()`, `@Query()`), status codes, and delegating to services.
   - **Services**: Contain pure business logic, orchestration, and domain rules.
   - **Gateways**: Handle WebSocket real-time event routing and delegate state updates to services.
   - **Data Access / Repositories**: Encapsulate database interactions (Prisma queries, transactions).

4. **ESM Import Conventions**:
   - When compiling to `nodenext` / ES Modules, always append `.js` extension to local relative file imports:
     ```typescript
     import { UsersService } from './users.service.js';
     import { CreateUserDto } from './dto/create-user.dto.js';
     ```

## 2. DTO Validation & Transformation

Always enforce strict DTO validation globally:
```typescript
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,              // Strips non-whitelisted properties
    forbidNonWhitelisted: true,  // Rejects requests with unexpected fields
    transform: true,              // Automatically transforms payloads to DTO instances
    transformOptions: { enableImplicitConversion: true },
  }),
);
```

Use `class-validator` and `class-transformer` decorators in every DTO:
```typescript
import { IsString, IsNotEmpty, MinLength, MaxLength, IsEnum } from 'class-validator';

export class SubmitPromptDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(4000)
  prompt: string;
}
```

## 3. Global Exception Handling & Logging

- Never expose unhandled database errors or stack traces to clients in production.
- Use built-in NestJS HTTP exceptions (`BadRequestException`, `UnauthorizedException`, `ForbiddenException`, `NotFoundException`, `ConflictException`).
- Implement custom exception filters when transforming Prisma error codes (e.g. `P2002` unique constraint violation -> `409 Conflict`).
