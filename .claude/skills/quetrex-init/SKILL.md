# Quetrex Init

Interactive project initialization wizard that configures your development environment.

## Usage

```
/quetrex-init
```

## Workflow

### Step 1: Check Prerequisites

Before starting, verify these are installed:

```bash
# Check Docker
docker --version

# Check Node.js
node --version

# Check Git
git --version
```

**If Docker is missing**, inform the user:
> Docker is required for local services (GlitchTip, PostgreSQL, Redis).
> Install from: https://docs.docker.com/get-docker/

### Step 2: Ask Configuration Questions

Use the `AskUserQuestion` tool to gather preferences:

#### Question 1: Scope
```
Where should configurations be applied?
- This project only (./claude/)
- Global (~/.claude/)
- Both (shared settings global, project-specific local)
```

#### Question 2: Error Monitoring
```
Which error monitoring solution?
- GlitchTip (self-hosted, Sentry-compatible) [Recommended]
- None (skip for now)
```

#### Question 3: Database
```
Which database setup?
- PostgreSQL via Docker (local dev)
- Neon (serverless PostgreSQL)
- None (skip for now)
```

#### Question 4: Caching
```
Which caching solution?
- Upstash Redis (cloud, already configured)
- Redis via Docker (local dev)
- None (skip for now)
```

#### Question 5: MCP Servers
```
Which MCP servers to enable?
- Playwright (E2E testing) [Recommended]
- Upstash (Redis management)
- Drizzle (Database, requires package.json)
```

### Step 3: Generate Configurations

Based on answers, generate the appropriate files:

---

## Configuration Templates

### GlitchTip Setup

**Prerequisites:** Docker installed and running

#### 1. Create docker-compose.glitchtip.yml

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: glitchtip
      POSTGRES_USER: glitchtip
      POSTGRES_PASSWORD: glitchtip_local_dev
    volumes:
      - glitchtip-postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U glitchtip"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  web:
    image: glitchtip/glitchtip
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://glitchtip:glitchtip_local_dev@postgres:5432/glitchtip
      REDIS_URL: redis://redis:6379/0
      SECRET_KEY: change-me-in-production-use-random-string
      PORT: 8000
      EMAIL_URL: consolemail://
      GLITCHTIP_DOMAIN: http://localhost:8000
      DEFAULT_FROM_EMAIL: glitchtip@localhost
      CELERY_WORKER_AUTOSCALE: "1,3"
      CELERY_WORKER_MAX_TASKS_PER_CHILD: "10000"
    volumes:
      - glitchtip-uploads:/code/uploads

  worker:
    image: glitchtip/glitchtip
    command: ./bin/run-celery-with-beat.sh
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://glitchtip:glitchtip_local_dev@postgres:5432/glitchtip
      REDIS_URL: redis://redis:6379/0
      SECRET_KEY: change-me-in-production-use-random-string
      EMAIL_URL: consolemail://
      GLITCHTIP_DOMAIN: http://localhost:8000
      DEFAULT_FROM_EMAIL: glitchtip@localhost
      CELERY_WORKER_AUTOSCALE: "1,3"
      CELERY_WORKER_MAX_TASKS_PER_CHILD: "10000"

volumes:
  glitchtip-postgres:
  glitchtip-uploads:
```

#### 2. Create scripts/glitchtip.sh

```bash
#!/bin/bash
set -e

COMPOSE_FILE="docker-compose.glitchtip.yml"

case "$1" in
  start)
    echo "Starting GlitchTip..."
    docker compose -f $COMPOSE_FILE up -d
    echo ""
    echo "GlitchTip is starting at http://localhost:8000"
    echo "First run? Create an account at http://localhost:8000/register"
    ;;
  stop)
    echo "Stopping GlitchTip..."
    docker compose -f $COMPOSE_FILE down
    ;;
  logs)
    docker compose -f $COMPOSE_FILE logs -f "${@:2}"
    ;;
  status)
    docker compose -f $COMPOSE_FILE ps
    ;;
  reset)
    echo "Resetting GlitchTip (removes all data)..."
    docker compose -f $COMPOSE_FILE down -v
    echo "Done. Run './scripts/glitchtip.sh start' to start fresh."
    ;;
  *)
    echo "Usage: $0 {start|stop|logs|status|reset}"
    exit 1
    ;;
esac
```

#### 3. Add to .env.local

```bash
# GlitchTip Error Monitoring (local dev)
# Get DSN from: http://localhost:8000 after creating a project
NEXT_PUBLIC_GLITCHTIP_DSN=http://YOUR_KEY@localhost:8000/1
```

#### 4. Install Sentry SDK (works with GlitchTip)

```bash
npm install @sentry/nextjs
```

#### 5. Create sentry.client.config.ts

```typescript
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_GLITCHTIP_DSN,

  // Only enable in development if DSN is set
  enabled: !!process.env.NEXT_PUBLIC_GLITCHTIP_DSN,

  // Adjust sample rate for development
  tracesSampleRate: 1.0,

  // Capture 100% of errors in dev
  sampleRate: 1.0,
});
```

#### 6. Update next.config.ts

```typescript
import { withSentryConfig } from "@sentry/nextjs";

const nextConfig = {
  // your existing config
};

export default withSentryConfig(nextConfig, {
  // Suppresses source map upload (not needed for local GlitchTip)
  silent: true,

  // Disable telemetry
  telemetry: false,
});
```

---

### PostgreSQL Docker Setup

**File:** `docker-compose.postgres.yml`

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:16
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: quetrex_dev
      POSTGRES_USER: quetrex
      POSTGRES_PASSWORD: quetrex_local_dev
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U quetrex -d quetrex_dev"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres-data:
```

**Add to .env.local:**
```bash
DATABASE_URL=postgresql://quetrex:quetrex_local_dev@localhost:5432/quetrex_dev
```

---

### Redis Docker Setup

**File:** `docker-compose.redis.yml`

```yaml
version: "3.8"

services:
  redis:
    image: redis:7
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes

volumes:
  redis-data:
```

**Add to .env.local:**
```bash
REDIS_URL=redis://localhost:6379
```

---

### Combined Docker Setup

If multiple services selected, create a unified `docker-compose.yml`:

```yaml
version: "3.8"

services:
  # Include selected services here

volumes:
  # Include required volumes
```

---

## Post-Configuration Steps

After generating configs, provide these instructions:

### For GlitchTip:
1. Run `chmod +x scripts/glitchtip.sh`
2. Run `./scripts/glitchtip.sh start`
3. Open http://localhost:8000 and create an account
4. Create a new project and copy the DSN
5. Update `NEXT_PUBLIC_GLITCHTIP_DSN` in `.env.local`

### For PostgreSQL:
1. Run `docker compose -f docker-compose.postgres.yml up -d`
2. Run `npx drizzle-kit push` to sync schema

### For MCP Servers:
1. Restart Claude Code to load new servers
2. Verify with `/mcp` command

---

## File Updates

### Update .gitignore
Add if not present:
```
# Docker volumes (don't commit local data)
docker-compose.override.yml
```

### Update CLAUDE.md
Add configured services to the stack documentation.

### Update .mcp.json
Add/remove MCP servers based on selections.

---

## Example Session

```
User: /quetrex-init

Claude: Let me check your prerequisites first.
[Runs docker --version, node --version, git --version]

All prerequisites met. Let me ask you some questions to configure your environment.

[AskUserQuestion: Scope]
User selects: "This project only"

[AskUserQuestion: Error Monitoring]
User selects: "GlitchTip"

[AskUserQuestion: Database]
User selects: "PostgreSQL via Docker"

[AskUserQuestion: Caching]
User selects: "Upstash Redis (already configured)"

[AskUserQuestion: MCP Servers]
User selects: "Playwright, Upstash"

Claude: Creating configurations...
- Created docker-compose.glitchtip.yml
- Created docker-compose.postgres.yml
- Created scripts/glitchtip.sh
- Updated .env.local
- Updated .mcp.json

Next steps:
1. Run `./scripts/glitchtip.sh start` to start GlitchTip
2. Open http://localhost:8000 and create an account
3. Create a project and copy the DSN to .env.local
4. Restart Claude Code to load MCP servers
```
