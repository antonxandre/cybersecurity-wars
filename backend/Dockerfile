# -------------------------------------------------------------
# Stage 1: Build NestJS application and Prisma contract
# -------------------------------------------------------------
FROM node:24-alpine AS builder

WORKDIR /app

# Install build dependencies for native modules (Argon2)
RUN apk add --no-cache python3 make g++

COPY package*.json ./
RUN npm ci

COPY tsconfig*.json ./
COPY prisma.config.ts ./
COPY prisma ./prisma
COPY src ./src

# Emit contract & compile TypeScript to dist/
RUN npx prisma contract emit
RUN npm run build

# Prune dev dependencies for production image
RUN npm prune --omit=dev

# -------------------------------------------------------------
# Stage 2: Production Minimal Runtime
# -------------------------------------------------------------
FROM node:24-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000

# Install runtime dependencies for native bindings if required
RUN apk add --no-cache curl

# Run as non-root user for container security
USER node

COPY --chown=node:node package*.json ./
COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node --from=builder /app/dist ./dist
COPY --chown=node:node --from=builder /app/prisma ./prisma

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

CMD ["node", "dist/src/main.js"]
