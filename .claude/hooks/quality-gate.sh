#!/bin/bash
# Quality gate - validates ALL quality standards before allowing exit
# BLOCKS exit if any issues exist - enforces HARD RULES
# Runs on Stop hook

SESSION_MARKER="/tmp/claude-modified-$PPID"

# Check if modifications were made this session
if [ ! -f "$SESSION_MARKER" ]; then
  echo '{"decision": "approve"}'
  exit 0
fi

# Only run in directories with package.json
if [ ! -f "package.json" ]; then
  rm -f "$SESSION_MARKER"
  echo '{"decision": "approve"}'
  exit 0
fi

# Initialize
FAILURES=""
PASSED=true

# ============================================
# CODE QUALITY CHECKS (HARD RULES 1-4)
# ============================================

# Check 1: TypeScript - ZERO ERRORS, ZERO WARNINGS
if [ -f "tsconfig.json" ]; then
  TYPE_OUTPUT=$(npm run type-check 2>&1) || true

  # Check for errors
  if echo "$TYPE_OUTPUT" | grep -qE "(error TS|Error:)"; then
    ERROR_LINES=$(echo "$TYPE_OUTPUT" | grep -E "error TS" | head -10)
    FAILURES="$FAILURES\n\n## TypeScript Errors (HARD RULE: Zero Tolerance)\n\`\`\`\n$ERROR_LINES\n\`\`\`"
    PASSED=false
  fi

  # Check for warnings (WARNINGS ARE ERRORS)
  if echo "$TYPE_OUTPUT" | grep -qE "(warning|Warning)"; then
    WARN_LINES=$(echo "$TYPE_OUTPUT" | grep -iE "warning" | head -10)
    FAILURES="$FAILURES\n\n## TypeScript Warnings (HARD RULE: Warnings = Errors)\n\`\`\`\n$WARN_LINES\n\`\`\`"
    PASSED=false
  fi
fi

# Check 2: Lint - ZERO ERRORS, ZERO WARNINGS
if grep -q '"lint"' package.json 2>/dev/null; then
  LINT_OUTPUT=$(npm run lint 2>&1) || true

  # Check for errors
  ERROR_COUNT=$(echo "$LINT_OUTPUT" | grep -cE "error" 2>/dev/null || echo "0")
  if [ "$ERROR_COUNT" -gt 0 ]; then
    ERROR_LINES=$(echo "$LINT_OUTPUT" | grep -E "error" | head -10)
    FAILURES="$FAILURES\n\n## Lint Errors ($ERROR_COUNT found)\n\`\`\`\n$ERROR_LINES\n\`\`\`"
    PASSED=false
  fi

  # Check for warnings (WARNINGS ARE ERRORS)
  WARN_COUNT=$(echo "$LINT_OUTPUT" | grep -cE "warning|warn" 2>/dev/null || echo "0")
  if [ "$WARN_COUNT" -gt 0 ]; then
    WARN_LINES=$(echo "$LINT_OUTPUT" | grep -iE "warning|warn" | head -10)
    FAILURES="$FAILURES\n\n## Lint Warnings (HARD RULE: Warnings = Errors)\n\`\`\`\n$WARN_LINES\n\`\`\`"
    PASSED=false
  fi
fi

# Check 3: Tests - ALL MUST PASS
if grep -q '"test"' package.json 2>/dev/null; then
  TEST_OUTPUT=$(npm test 2>&1) || true

  if echo "$TEST_OUTPUT" | grep -qE "(FAIL|failed|Error|✗|×)"; then
    FAIL_LINES=$(echo "$TEST_OUTPUT" | grep -E "(FAIL|failed|✗|×)" | head -10)
    FAILURES="$FAILURES\n\n## Test Failures (HARD RULE: 100% Pass Required)\n\`\`\`\n$FAIL_LINES\n\`\`\`\nFix your CODE to pass tests. NEVER modify tests."
    PASSED=false
  fi
fi

# ============================================
# GIT HYGIENE CHECKS (HARD RULES 6-7)
# ============================================

if git rev-parse --git-dir > /dev/null 2>&1; then
  # Check 4: Must be on feature branch in worktree (HARD RULE 6)
  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
  if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    FAILURES="$FAILURES\n\n## Working on Main Branch (HARD RULE VIOLATION)\nYou are on \`$CURRENT_BRANCH\`. Work MUST happen in worktrees with feature branches.\n\nCreate a worktree: \`git worktree add ../worktrees/issue-<name> -b issue/<name>\`"
    PASSED=false
  fi

  # Check 5: Uncommitted changes
  if [ -n "$(git status --porcelain)" ]; then
    CHANGED_FILES=$(git status --porcelain | head -10)
    FAILURES="$FAILURES\n\n## Uncommitted Changes\n\`\`\`\n$CHANGED_FILES\n\`\`\`\nCommit or stash changes before exiting."
    PASSED=false
  fi
fi

# ============================================
# DECISION
# ============================================

if [ "$PASSED" = true ]; then
  rm -f "$SESSION_MARKER"
  echo '{"decision": "approve"}'
else
  ESCAPED_FAILURES=$(echo -e "$FAILURES" | sed 's/"/\\"/g' | tr '\n' ' ')
  echo "{\"decision\": \"block\", \"reason\": \"HARD RULES VIOLATED. Fix these issues before exiting:$ESCAPED_FAILURES\"}"
fi
