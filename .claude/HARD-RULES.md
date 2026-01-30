# HARD RULES - NON-NEGOTIABLE

**Owner:** Glen Barnhardt
**Effective:** 2026-01-22
**Enforcement:** Hooks + Agent Instructions + Human Gates

These rules are ABSOLUTE. No exceptions without explicit human approval in chat.

---

## Code Quality Rules

### 1. NO CONFIG CHANGES TO FIX BROKEN CODE

**Rule:** Configuration files are SACRED. Never modify them to make broken code pass.

**Protected files:**
- `tsconfig.json` - TypeScript configuration
- `biome.json` / `biome.jsonc` - Linter configuration
- `eslint.config.js` / `.eslintrc.*` - ESLint configuration
- `vitest.config.ts` / `vitest.config.js` - Test configuration
- `next.config.ts` / `next.config.js` - Next.js configuration
- `tailwind.config.ts` - Tailwind configuration
- `drizzle.config.ts` - Database configuration

**If code doesn't compile/lint/test:**
1. FIX THE CODE
2. NEVER weaken the config
3. Ask for help if stuck

### 2. ZERO WARNINGS TOLERANCE

**Rule:** We do not accept warnings. Warnings are errors.

**This applies to:**
- TypeScript warnings → Fix them
- ESLint warnings → Fix them
- Biome warnings → Fix them
- React warnings → Fix them
- Build warnings → Fix them

**No exceptions.** Clean code or no code.

### 3. TESTS ARE IMMUTABLE

**Rule:** Tests define the contract. Code adapts to tests, NEVER vice versa.

**FORBIDDEN:**
- Modifying test expectations to match broken code
- Deleting tests that fail
- Skipping tests (`.skip`, `.todo`) without approval
- Weakening test assertions
- Removing edge case coverage

**If tests fail:**
1. Read the test carefully
2. Understand what it expects
3. FIX YOUR CODE to meet the expectation
4. NEVER touch the test file

### 4. WRITE CLEAN CODE THE FIRST TIME

**Rule:** No "fix it later" mentality. Code is clean or it doesn't exist.

**Requirements:**
- Strict TypeScript (no `any`, no `@ts-ignore`, no `@ts-expect-error`)
- Proper error handling (no silent catches)
- Meaningful variable names
- Proper typing for all function parameters and returns
- No unused imports, variables, or code

**When unsure:**
1. Use Context7 to read latest documentation
2. Check the skill files for patterns
3. Ask the user for clarification
4. NEVER guess and hope

---

## Documentation Rules

### 5. USE CURRENT DOCUMENTATION

**Rule:** Always use the LATEST documentation for our stack versions.

**Our Stack (as of 2026-01-22):**
- Next.js 16 (NOT 15, NOT 14)
- React 19.2
- TypeScript 5.x (strict mode)
- TanStack Query v5
- Zustand 5.x
- Drizzle ORM (latest)

**How to stay current:**
```
Use Context7 MCP tool to fetch latest docs:
- mcp__context7__resolve-library-id
- mcp__context7__query-docs
```

**NEVER:**
- Use deprecated patterns
- Copy old Stack Overflow answers
- Guess at API changes
- Use patterns from older versions

---

## Git Rules

### 6. WORKTREES WITH BRANCHES - ALWAYS

**Rule:** All work happens in git worktrees with feature branches.

**Workflow:**
```bash
# Create worktree for new issue
git worktree add ../worktrees/issue-<name> -b issue/<name>

# Work happens in worktree
cd ../worktrees/issue-<name>

# Never work directly on main
```

**FORBIDDEN:**
- Working directly on main branch
- Committing to main
- Pushing to main (force or otherwise)
- Creating PRs from main

**Override:** Only with explicit human approval in chat.

### 7. NO PR WITHOUT 100% CLEAN CODE

**Rule:** Pull requests are only created when code is PERFECT.

**PR Checklist (ALL must pass):**
- [ ] TypeScript compiles with zero errors
- [ ] TypeScript compiles with zero warnings
- [ ] All linting passes with zero errors
- [ ] All linting passes with zero warnings
- [ ] All tests pass (100%)
- [ ] Test coverage meets threshold (80%+ on new code)
- [ ] No console.log statements (unless intentional logging)
- [ ] No TODO comments without linked issues
- [ ] No commented-out code

**If ANY item fails:** Fix it. Do not create the PR.

### 8. NO DEPLOYMENT WITHOUT HUMAN APPROVAL

**Rule:** Deployments ALWAYS require human approval.

**Agents CANNOT:**
- Run `fly deploy`
- Run `vercel deploy`
- Push to production branches
- Trigger deployment workflows
- Bypass GitHub Environment protections

**Deployment flow:**
1. Agent creates PR
2. Human reviews PR
3. Human approves PR
4. Human triggers deployment (or auto-deploy on merge)
5. Production deployment requires GitHub Environment approval

---

## Agent Rules

### 9. SPAWN SUB-AGENTS FOR COMPLEX WORK

**Rule:** When work benefits from parallelization, spawn sub-agents.

**When to spawn:**
- Multiple independent files to modify
- Research + implementation can happen in parallel
- Testing can happen while documenting
- Database work separate from frontend work

**How to spawn:**
```
Use the Task tool with appropriate subagent_type:
- architect: For analysis and planning
- developer: For implementation
- test-writer: For test creation
- qa: For verification
```

**Benefits:**
- Faster completion
- Cleaner separation of concerns
- Better context management
- Parallel execution

### 10. MULTIPLE AGENTS, ONE WORKTREE

**Rule:** Multiple agents can work on the same issue in one worktree.

**Coordination:**
- Use `.issue/` directory for shared state
- Use `.issue/context.json` for issue metadata
- Use `.issue/todo.json` for task tracking
- Use atomic file writes to prevent conflicts

**Workflow:**
```
Architect creates plan → writes .issue/todo.json
Developer reads plan → implements code
Test-writer reads code → writes tests
QA reads all → verifies quality
Git-workflow reads all → creates PR
```

---

## Enforcement

### Hook Enforcement

These rules are enforced by hooks that CANNOT be bypassed:

| Rule | Hook | Trigger |
|------|------|---------|
| No config changes | config-guard.sh | PreToolUse (Write\|Edit) |
| No test changes | test-guard.sh | PreToolUse (Write\|Edit) |
| No main commits | enforce-branch.sh | PreToolUse (Bash) |
| No force-push | require-approval.sh | PreToolUse (Bash) |
| TypeScript clean | post-edit-check.sh | PostToolUse (Write\|Edit) |
| Lint clean | lint-check.sh | PostToolUse (Write\|Edit) |
| Edit tracking | track-modifications.sh | PostToolUse (Write\|Edit) |
| Tests + coverage | quality-gate.sh | Stop |

### Human Gates

These rules require human intervention:

| Rule | Gate | Location |
|------|------|----------|
| PR approval | Branch protection | GitHub |
| Production deploy | Environment protection | GitHub |
| Rule override | Explicit approval | Chat |

**Note:** Agents CAN merge PRs after human review approval via branch protection. The `/close-issue` skill polls for `reviewDecision = APPROVED`, then runs `gh pr merge --merge --delete-branch`.

---

## Override Process

To override ANY hard rule:

1. Agent must ASK in chat: "I need to override [RULE] because [REASON]"
2. Human must EXPLICITLY approve: "Approved: [RULE] override for [SCOPE]"
3. Override applies ONLY to stated scope
4. Override expires when task completes

**Example:**
```
Agent: "I need to override the test immutability rule because the test
has a bug that tests the wrong behavior. The test expects 404 but the
API spec says it should return 400 for invalid input."

Human: "Approved: test modification override for the 400/404 status code fix only."
```

---

## Summary

These 10 rules form the foundation of our development practice:

1. **NO CONFIG CHANGES** - Fix code, not configs
2. **ZERO WARNINGS** - Warnings are errors
3. **TESTS IMMUTABLE** - Code adapts to tests
4. **CLEAN CODE FIRST** - No "fix later"
5. **CURRENT DOCS** - Use Context7 for latest
6. **WORKTREES ALWAYS** - Feature branches in worktrees
7. **100% CLEAN PRs** - Perfect or no PR
8. **HUMAN DEPLOY** - No auto-deployment
9. **SUB-AGENTS** - Parallelize when beneficial
10. **SHARED WORKTREES** - Multiple agents, one worktree

**Remember:** These rules exist to produce excellent software. They are not obstacles - they are guardrails that keep us shipping clean, tested, production-ready code.

---

*Last updated: 2026-01-22 by Glen Barnhardt with Claude Code*
