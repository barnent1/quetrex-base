# Handover Document: Stack, Agents & Skills Alignment Audit

**Date:** 2026-01-22
**Session:** Implementation of comprehensive development infrastructure improvements

---

## Executive Summary

This session implemented a complete audit and enhancement of the development infrastructure, addressing gaps in design thinking, testing, cross-technology integration, and deployment safety. All phases are **COMPLETE**.

---

## What Was Implemented

### Phase 5: Git Workflow & Deployment Gates (FOUNDATION)

**Purpose:** Establish infrastructure-enforced human approval gates to prevent AI from deploying to production without human review.

#### Files Created

1. **`.github/workflows/deploy.yml`**
   - CI/CD pipeline with test → staging → production flow
   - `staging` environment: auto-deploys after tests pass
   - `production` environment: **REQUIRES HUMAN APPROVAL** in GitHub UI
   - Uses Fly.io for deployment (`flyctl deploy`)

2. **`scripts/linear-poller.ts`**
   - TypeScript service that polls Linear API every 5 minutes
   - Looks for issues with `auto-process` label
   - Automatically creates worktree, WezTerm tab, and starts Claude
   - Enables partners to create issues from phone/browser

#### Files Modified

1. **`.claude/agents/git-workflow.md`**
   - Added "CRITICAL: No Deploy Commands" section
   - Removed all deploy capabilities
   - Added Linear issue linking to PRs
   - Agent now creates PR but does NOT merge

2. **`.claude/skills/close-issue/SKILL.md`**
   - Removed auto-merge (`gh pr merge`)
   - Now waits for human to approve and merge PR
   - Polls PR status before cleanup
   - Only closes tab after PR is confirmed merged

3. **`.claude/skills/create-issue/SKILL.md`**
   - Updated context.json schema with Linear fields:
     - `linearIssueId`, `linearUrl`, `prNumber`, `status`
   - Added documentation for remote entry via Linear

---

### Phase 1: Design Layer

**Purpose:** Add intentional design thinking to avoid generic AI aesthetics.

#### Files Created

1. **`.claude/skills/design/SKILL.md`** (Comprehensive - ~500 lines)
   - Creative unlocking directive
   - 8 aesthetic directions (Brutalist, Maximalist, Luxury, Playful, etc.)
   - Typography rules (NEVER use Inter, Roboto, Arial)
   - Font pairing strategies
   - Color strategy with CSS variables
   - Motion philosophy (high-impact moments vs micro-interactions)
   - Spatial composition (asymmetry, negative space, overlap)
   - ShadCN + Framer Motion integration patterns
   - Anti-patterns to avoid
   - Design system output format template

2. **`.claude/agents/designer.md`**
   - Runs after Architect, before Developer
   - Reads requirements and architecture
   - Outputs `.issue/design-system.md` with:
     - Aesthetic direction + rationale
     - Color palette (CSS variables)
     - Typography selections
     - Animation strategy
     - Component specifications

#### Files Modified

1. **`.claude/agents/developer.md`**
   - Now reads `.issue/design-system.md` before implementing UI
   - Must follow design specifications exactly
   - Added "Design System Implementation" section
   - Reports design system elements applied in output

---

### Phase 2: Testing Infrastructure

**Purpose:** Provide testing guidance and ensure new code has adequate coverage.

#### Files Created

1. **`.claude/skills/testing/SKILL.md`** (Comprehensive - ~600 lines)
   - Vitest configuration
   - Test setup file with MSW
   - File naming conventions
   - Unit testing patterns
   - Component testing with React Testing Library
   - Testing TanStack Query (QueryClient wrapper)
   - Testing Zustand stores (state reset)
   - API route testing
   - MSW for HTTP mocking
   - Playwright E2E patterns
   - Best practices

2. **`.claude/agents/test-writer.md`**
   - Runs after Developer, before QA
   - Analyzes completed implementation
   - Writes appropriate tests:
     - Unit tests for utilities
     - Component tests for React components
     - API route tests
     - Hook tests
   - Ensures >80% coverage on new code

#### Files Modified

1. **`.claude/agents/architect.md`**
   - Added "Test Strategy" section to architecture decision template
   - Specifies which test types needed (unit, component, E2E)
   - Added `testType` field to todo.json items
   - Includes test strategy guidelines table

2. **`.claude/agents/qa.md`**
   - Added "Check Test Coverage" step (`npm run test:coverage`)
   - Added "Verify Tests Exist" step
   - Coverage requirement: >80% on new code
   - Added "Test Files Verification" to output format
   - Rejection criteria now includes coverage check

---

### Phase 3: Integration Patterns

**Purpose:** Show how technologies work together instead of in isolation.

#### Files Created

1. **`.claude/skills/stack-integration/SKILL.md`** (Comprehensive - ~400 lines)
   - Cache layer strategy decision tree
   - Multi-layer cache example (Next.js + Redis + TanStack Query)
   - Cache invalidation flow diagram
   - State management decision tree
   - TanStack Query + Zustand integration
   - Full-stack data flow (create operation)
   - Next.js 16 Cache + TanStack Query patterns
   - Avoiding double caching
   - ShadCN + Framer Motion integration
   - Drizzle + Next.js cache integration
   - Upstash Redis + Next.js cache

#### Files Modified

1. **`.claude/skills/zustand/SKILL.md`**
   - Added expanded TanStack Query integration section
   - Combining filters (Zustand) with data (TanStack Query)
   - Optimistic updates with Zustand rollback

2. **`.claude/skills/drizzle-postgres/SKILL.md`**
   - Added Next.js 16 cache integration
   - Cached database queries with `cacheTag`
   - Cache invalidation on mutation
   - Type exports for frontend
   - Multi-layer caching with Redis

3. **`.claude/skills/upstash-redis/SKILL.md`**
   - Added Next.js 16 cache integration
   - When to use which cache table
   - Multi-layer cache pattern
   - Rate limiting in middleware

4. **`.claude/skills/tanstack-query/SKILL.md`**
   - Added Next.js 16 cache integration
   - Server-side prefetch with HydrationBoundary
   - Avoiding double caching
   - Full invalidation chain
   - Zustand integration

5. **`.claude/skills/shadcn-ui/SKILL.md`**
   - Added Framer Motion integration section
   - Animated Dialog, Card, Button, Sheet patterns
   - Staggered list with cards
   - forceMount pattern for AnimatePresence

6. **`.claude/skills/framer-motion/SKILL.md`**
   - Added ShadCN UI integration section
   - Animated ShadCN components
   - forceMount + AnimatePresence pattern
   - motion() wrapper usage

7. **`.claude/skills/nextjs-16/SKILL.md`**
   - Added TanStack Query integration
   - Server-side prefetch
   - Combining "use cache" with TanStack Query
   - Upstash Redis integration
   - Rate limiting in middleware

---

### Phase 4: API Patterns

**Purpose:** Provide API design guidance missing from existing skills.

#### Files Created

1. **`.claude/skills/api-patterns/SKILL.md`** (Comprehensive - ~400 lines)
   - Route handler basics
   - Zod schema validation patterns
   - Typed error responses (ApiError classes)
   - Error handler wrapper (`withErrorHandler`)
   - Rate limiting integration
   - Authentication middleware
   - Response helpers (success, created, noContent, paginated)
   - Query parameter parsing
   - File structure recommendation
   - Complete example combining all patterns

---

### Documentation Updates

1. **`.claude/CLAUDE.md`**
   - Updated Skills Available section (13 skills now)
   - Updated Agents Available section (7 agents now)
   - Added Agent Workflow diagram
   - Added Human Gates section
   - Added workflow rules for PRs, deployment, coverage

---

## New Agent Workflow

```
Product Manager → Architect → Designer → Database Architect → Developer → Test Writer → QA → Git Workflow
     ↓               ↓           ↓              ↓                ↓            ↓         ↓         ↓
  PRD/Reqs      Task Plan    Design Sys    Schema Design      Code        Tests     Verify   PR Created
```

**Human Gates (Infrastructure-Enforced):**
1. PR Review - Branch protection requires approval
2. Production Deploy - GitHub Environment requires approval

---

## Handoff Files Created by Agents

| File | Created By | Consumed By |
|------|------------|-------------|
| `.issue/requirements.md` | Product Manager | Architect, Designer |
| `.issue/architecture-decision.md` | Architect | Designer, Developer |
| `.issue/design-system.md` | Designer | Developer |
| `.issue/schema-changes.md` | Database Architect | Developer |
| `.issue/todo.json` | Architect | Developer, Test Writer, QA |
| `.issue/context.json` | create-issue / linear-poller | All agents |

---

## Remaining Setup (NOT YET DONE)

### 1. GitHub Environments Configuration

Run these commands to configure GitHub environments:

```bash
# Create staging environment (auto-deploy)
gh api -X PUT repos/barnent1/quetrex-base/environments/staging

# Create production environment (requires human approval)
gh api -X PUT repos/barnent1/quetrex-base/environments/production \
  -f 'reviewers[][type]=User' \
  -F 'reviewers[][id]=2037033' \
  -F 'prevent_self_review=true'
```

### 2. Branch Protection Rules

```bash
gh api -X PUT repos/barnent1/quetrex-base/branches/main/protection \
  -f 'required_pull_request_reviews[required_approving_review_count]=1' \
  -f 'required_pull_request_reviews[dismiss_stale_reviews]=true' \
  -f 'required_status_checks[strict]=true' \
  -f 'required_status_checks[contexts][]=test' \
  -f 'enforce_admins=false'
```

### 3. Linear Integration

1. Create Linear API key: https://linear.app/settings/api
2. Create Linear labels: `auto-process`, `in-progress`, `needs-review`, `completed`, `blocked`
3. Set environment variables:
   ```bash
   export LINEAR_API_KEY="lin_api_..."
   export LINEAR_TEAM_ID="QTX"  # Your team key
   export PROJECT_PATH="/Users/barnent1/Projects/quetrex-base"
   ```
4. Run the poller:
   ```bash
   # One-time
   npx tsx scripts/linear-poller.ts

   # With pm2 (persistent)
   pm2 start scripts/linear-poller.ts --name linear-poller --interpreter npx --interpreter-args tsx
   ```

### 4. GitHub Secrets/Variables

Set in GitHub repository settings:
- `FLY_API_TOKEN` - Secret for Fly.io deployment
- `FLY_APP_STAGING` - Variable for staging app name
- `FLY_APP_PRODUCTION` - Variable for production app name

---

## Verification Checklist

After setup, verify:

- [ ] GitHub Environment `staging` exists
- [ ] GitHub Environment `production` exists with required reviewers
- [ ] Branch protection on `main` requires PR approval
- [ ] Linear poller runs and picks up `auto-process` issues
- [ ] Agents cannot deploy (no flyctl/vercel commands)
- [ ] Agents cannot auto-merge PRs
- [ ] Production deploy requires clicking "Approve" in GitHub UI

---

## File Inventory

### New Files Created (12)
```
.github/workflows/deploy.yml
scripts/linear-poller.ts
.claude/skills/design/SKILL.md
.claude/skills/testing/SKILL.md
.claude/skills/stack-integration/SKILL.md
.claude/skills/api-patterns/SKILL.md
.claude/agents/designer.md
.claude/agents/test-writer.md
.claude/docs/handover.md (this file)
```

### Modified Files (14)
```
.claude/CLAUDE.md
.claude/agents/architect.md
.claude/agents/developer.md
.claude/agents/git-workflow.md
.claude/agents/qa.md
.claude/skills/close-issue/SKILL.md
.claude/skills/create-issue/SKILL.md
.claude/skills/drizzle-postgres/SKILL.md
.claude/skills/framer-motion/SKILL.md
.claude/skills/nextjs-16/SKILL.md
.claude/skills/shadcn-ui/SKILL.md
.claude/skills/tanstack-query/SKILL.md
.claude/skills/upstash-redis/SKILL.md
.claude/skills/zustand/SKILL.md
```

---

## Key Decisions Made

1. **Phase 5 First** - Deployment gates are foundational for safe development
2. **No Auto-Merge** - All PRs require human approval
3. **No Deploy Commands** - Agents physically cannot deploy
4. **80% Coverage Minimum** - QA rejects code below threshold
5. **Design System Required** - For UI work, designer agent runs before developer
6. **Single Cache Owner** - Choose Next.js OR TanStack Query, not both
7. **Linear Integration** - Partners can trigger workflows from phone/browser

---

## Contact

Implementation by: Glen Barnhardt with Claude Code
Session: Stack, Agents & Skills Alignment Audit
Status: **COMPLETE** (pending GitHub/Linear configuration)
