# Quetrex Base

## What This Is

Quetrex Base is a foundation for building web applications with a defined
technology stack, specialized AI agents, reusable skill patterns, and
quality enforcement.

## For Agents: Read This First

**MANDATORY:** Read and follow `.claude/HARD-RULES.md` before doing any work.
These 10 rules are non-negotiable and enforced by hooks and human gates.

Key rules:
- NO `any` types -- use proper TypeScript
- ZERO warnings -- warnings are errors
- Tests are immutable -- fix code, not tests
- Worktrees always -- never work on main
- Use Context7 for latest documentation
- 80% test coverage on new code

## How to Work

### Manual Workflow (Human-Driven)

#### Starting an Issue
`/create-issue <description>` creates a git worktree and feature branch
for isolated development.

#### Agent Workflow
Architect -> Designer -> Database Architect -> Developer -> Test Writer -> QA -> Git Workflow

#### Completing an Issue
`/close-issue <commit message>` runs quality checks (fail = stop), then
commits, pushes, creates a PR, and merges. Cleanup (worktree removal,
branch deletion, state verification) is **guaranteed** regardless of
whether mutation steps succeed or fail.

### Autonomous Pipeline (Task Runner)

Issues labeled `claude-code` in Linear are processed automatically through
the full agent pipeline by the quetrex-task-runner.

#### Pipeline States (Linear Workflow)
```
Queued -> Refining -> Architecting -> Designing -> Implementing -> Testing -> QA Gate -> In Review -> Done
                                                                                ↑          |
                                                                                └──────────┘
                                                                              (retry up to 5x)
```

Each Linear workflow state maps 1:1 to a pipeline stage. The runner
transitions states via the Linear GraphQL API.

#### Stage Details
| Stage | Agent | Purpose |
|-------|-------|---------|
| Refining | Product Manager | Turn underspecified issues into actionable specs |
| Architecting | Architect | Plan implementation, create todo.json |
| Designing | Designer | Create design direction (UI work only, skipped otherwise) |
| Implementing | Developer | Write the code (may span multiple sessions) |
| Testing | Test Writer | Write tests, verify >80% coverage |
| QA Gate | QA | Final quality verification (up to 5 retries) |
| In Review | Git Workflow | Create PR for human review |

#### Session Continuity
Each pipeline stage may span multiple CLI sessions. The runner manages
this via progress files in `.issue/`:

| File | Purpose |
|------|---------|
| `progress.md` | Human-readable log: what was done, what's next |
| `todo.json` | Feature list with `passing: true/false` per item |
| `stage-state.json` | Machine-readable: current stage, attempt count |
| `architecture-decision.md` | Architect output |
| `design-system.md` | Designer output |
| `init.sh` | Project-specific bootstrap script |
| `discoveries.md` | Non-obvious findings for learning extraction |

Agents **MUST** read these files on startup and update them on completion.
See each agent's "Session Continuity Harness" section for the protocol.

#### Communication
- **SMS (Twilio):** Questions to issue owner during spec refinement
- **Email:** Daily digest reports of pipeline progress
- **Linear Comments:** Structured updates at each stage transition

#### Continuous Learning
After every completed issue, the runner extracts learnings:
- **Project rules** → `.claude/rules/learned-patterns.md`
- **Extracted skills** → `.claude/skills/learned/`
- **Global knowledge** → `~/.claude/rules/` (cross-project, promoted manually)

See `.claude/prompts/learning-extraction.md` for the extraction protocol.

---

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
- `/design` - Design thinking, aesthetic patterns
- `/testing` - Vitest, RTL, Playwright patterns
- `/stack-integration` - Cross-technology integration
- `/api-patterns` - API design, Zod validation
- `/tab-control` - Create/update WezTerm tab name and color
- `/define-architecture` - Generate architecture docs with Mermaid diagrams and ADRs

## Agents Available
- `architect` - Strategic analysis and planning (use at START of features)
- `designer` - Visual design decisions (use for UI work)
- `database-architect` - Database design and migrations
- `developer` - Implementation specialist (follows design system)
- `test-writer` - Test implementation (writes tests for new code)
- `qa` - Quality assurance (includes coverage checking)
- `git-workflow` - Git operations (no deploy commands)
- `product-manager` - Requirements gathering (first for any work)

## Agent Workflow
```
Product Manager -> Architect -> Designer -> Database Architect -> Developer -> Test Writer -> QA -> Git Workflow
     |               |           |              |                |            |         |         |
  PRD/Reqs      Task Plan    Design Sys    Schema Design      Code        Tests     Verify   PR Created
```

In the autonomous pipeline, each agent reads/writes `.issue/` progress
files for session continuity. See agent definitions for harness protocol.

## Human Gates (Infrastructure-Enforced)
1. **PR Review** - Branch protection requires approval
2. **Production Deploy** - GitHub Environment requires approval

---

## Workflow Rules

- When creating branches, always state: "Branch `branch-name` created by Glen Barnhardt with Claude Code"
- PRs require human approval - agents cannot auto-merge
- Deployment requires human approval via GitHub Environments
- New code must have >80% test coverage
