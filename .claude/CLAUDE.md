# Glen Barnhardt's Stack

## Frontend/Framework
- **Next.js 16** - App Router, Turbopack, React Compiler, React 19.2
- **TypeScript** - Strict mode (NO `any` types allowed)
- **React 19.2** - View Transitions, useEffectEvent, Activity

## UI & Styling
- **ShadCN UI** - Component library
- **Tailwind CSS** - Utility-first styling
- **Framer Motion** - Animations

## State Management
- **TanStack Query (React Query v5)** - Server state
- **Zustand** - Client state

## Database & Backend
- **Drizzle ORM** - PostgreSQL database (snake_case DB, camelCase TS)
- **Upstash Redis** - Caching, rate limiting, sessions

## Skills Available
Use `/` skills for stack-specific patterns:
- `/nextjs-16` - App Router, caching, server components
- `/typescript-strict` - Strict mode patterns
- `/shadcn-ui` - Component patterns + Framer Motion integration
- `/tailwind-css` - Utility-first styling
- `/drizzle-postgres` - Database patterns + cache integration
- `/upstash-redis` - Caching, rate limiting + Next.js integration
- `/tanstack-query` - Server state + Next.js integration
- `/zustand` - Client state + TanStack Query integration
- `/framer-motion` - Animations + ShadCN integration
- `/design` - Design thinking, aesthetic patterns (NEW)
- `/testing` - Vitest, RTL, Playwright patterns (NEW)
- `/stack-integration` - Cross-technology integration (NEW)
- `/api-patterns` - API design, Zod validation (NEW)

## Agents Available
- `architect` - Strategic analysis and planning (use at START of features)
- `designer` - Visual design decisions (NEW - use for UI work)
- `database-architect` - Database design and migrations
- `developer` - Implementation specialist (follows design system)
- `test-writer` - Test implementation (NEW - writes tests for new code)
- `qa` - Quality assurance (includes coverage checking)
- `git-workflow` - Git operations (no deploy commands)

## Agent Workflow
```
Product Manager → Architect → Designer → Database Architect → Developer → Test Writer → QA → Git Workflow
     ↓               ↓           ↓              ↓                ↓            ↓         ↓         ↓
  PRD/Reqs      Task Plan    Design Sys    Schema Design      Code        Tests     Verify   PR Created
```

## Human Gates (Infrastructure-Enforced)
1. **PR Review** - Branch protection requires approval
2. **Production Deploy** - GitHub Environment requires approval

---

## Workflow Rules

- When creating branches, always state: "Branch `branch-name` created by Glen Barnhardt with Claude Code"
- PRs require human approval - agents cannot auto-merge
- Deployment requires human approval via GitHub Environments
- New code must have >80% test coverage
