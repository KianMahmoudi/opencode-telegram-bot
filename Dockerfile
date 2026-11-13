# Build stage
FROM node:22-bookworm-slim AS builder

WORKDIR /app

# Install only native build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy package files first for better layer caching
COPY package.json package-lock.json ./

# Install ALL dependencies (including dev for build)
RUN npm ci

# Copy TypeScript config and source code
COPY tsconfig.json ./
COPY src/ ./src/

# Build the project
RUN npm run build

# Prune dev dependencies from the final image
RUN npm prune --omit=dev


# Runtime stage
FROM node:22-bookworm-slim AS runtime

WORKDIR /app

# dumb-init (signal handling), ca-certificates (HTTPS), wget (startup health check)
RUN apt-get update && apt-get install -y --no-install-recommends \
    dumb-init \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install OpenCode CLI so `opencode serve` works inside the container
RUN npm install -g @opencode/cli

# Set production environment
ENV NODE_ENV=production

# Set persistent home for the bot
ENV OPENCODE_TELEGRAM_HOME=/app/data
ENV HOME=/home/node

# Create data directories with correct ownership for node user
RUN mkdir -p /app/data/logs /app/data/run && \
    chown -R node:node /app

# Copy built application and production dependencies from builder
COPY --from=builder --chown=node:node /app/dist ./dist
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/package.json ./package.json

# Copy startup script that launches opencode + bot together
COPY --chown=node:node start.sh ./start.sh
RUN chmod +x /app/start.sh

# Run as non-root node user (uid 1000)
USER node

# Probe the loopback health endpoint (BOT_HEALTH_PORT, 3100 by default in a container)
HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
    CMD ["node", "dist/runtime/healthcheck.js"]

# Single dumb-init entrypoint runs start.sh which starts both processes
ENTRYPOINT ["dumb-init", "--"]
CMD ["./start.sh"]
