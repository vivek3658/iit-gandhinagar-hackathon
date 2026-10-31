# ==============================================================================
# URJA ONE Backend - Production Multi-Stage Dockerfile
# Optimized for High-Throughput Scalability, Minimal Footprint & Security
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build & Compilation Stage
# ------------------------------------------------------------------------------
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

# Install build dependencies
RUN apk add --no-cache libc6-compat python3 make g++

# Install dependencies strictly from lockfile
COPY package.json package-lock.json ./
RUN npm ci

# Copy TypeScript source code and configuration
COPY tsconfig.json ./
COPY src/ ./src/

# Compile TypeScript to production JavaScript in dist/
RUN npm run build

# Prune dev dependencies for lean production image
RUN npm prune --omit=dev

# ------------------------------------------------------------------------------
# Stage 2: Minimal Production Runtime Stage
# ------------------------------------------------------------------------------
FROM node:20-alpine AS runner

WORKDIR /usr/src/app

# Add unprivileged system user for container security (never run as root)
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 fastify

# Install curl for container health check
RUN apk add --no-cache curl

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

# Copy production node_modules and built JavaScript
COPY --from=builder --chown=fastify:nodejs /usr/src/app/package.json ./package.json
COPY --from=builder --chown=fastify:nodejs /usr/src/app/node_modules ./node_modules
COPY --from=builder --chown=fastify:nodejs /usr/src/app/dist ./dist

# Switch to unprivileged user
USER fastify

# Expose HTTP port
EXPOSE 3000

# Container Healthcheck (returns HTTP 200 from Fastify /health endpoint)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://127.0.0.1:3000/health || exit 1

# Start Fastify server
CMD ["node", "dist/server.js"]
