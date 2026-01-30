---
name: close-issue
description: Complete git workflow - commit, PR, wait for human approval, cleanup
allowed-tools: Bash, Read
---

# Close Issue Workflow

Completes the git workflow: quality check, commit, push, create PR. Waits for human review approval, then merges and cleans up the worktree.

**Flow:** PR is created, agent polls for human review approval via branch protection, then merges with `--delete-branch` and cleans up the worktree.

## Usage

```
/close-issue feat: add user preferences
/close-issue fix: resolve login button issue
```

## Instructions

Execute ALL steps in order. Do NOT skip any step.

### Step 1: Pre-flight Checks

Execute this command:

```bash
BRANCH=$(git branch --show-current) && if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then echo "ERROR: Cannot close issue from main branch" && exit 1; fi && echo "On branch: $BRANCH"
```

If on main, STOP. Otherwise, run type-check:

```bash
npm run type-check
```

If type-check fails, STOP and report errors. Do NOT proceed.

### Step 2: Run Final QA

Execute:

```bash
npm run lint 2>&1 | head -30
```

If lint has errors, STOP and report. Do NOT proceed.

### Step 2.5: Run Tests

Execute:

```bash
npm run test:run 2>&1 | tail -20
```

If tests fail, STOP and report. Do NOT proceed.

### Step 3: Stage and Commit

First, review what will be staged:

```bash
git status
```

Stage tracked changes:

```bash
git add -u
```

Then review untracked files. Stage them explicitly by name only after verifying they belong in the commit (no `.env`, credentials, or temp files):

```bash
git status --short | grep '^??' | awk '{print $2}'
```

Stage appropriate untracked files individually:

```bash
git add <file1> <file2> ...
```

Verify the final staging:

```bash
git status
```

Then commit:

```bash
git commit -m "$(cat <<'EOF'
$ARGUMENTS

Branch created by Glen Barnhardt with the help of Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### Step 4: Push to Remote

Execute:

```bash
git push -u origin $(git branch --show-current)
```

### Step 5: Create PR (NO AUTO-MERGE)

Create the PR:

```bash
gh pr create --title "$ARGUMENTS" --body "$(cat <<'EOF'
## Summary
[Description based on commit message and changes]

## Test Plan
- [x] Type check passes
- [x] Lint passes
- [ ] Manual testing completed
- [ ] PR reviewed and approved

---
🤖 Generated with Claude Code

**Deployment Flow:**
1. Human approves and merges this PR
2. Staging deploy happens automatically
3. Human approves production deploy in GitHub UI
EOF
)"
```

### Step 6: Report and Wait for Human Approval

Output this message:

```
## PR Created - Awaiting Human Approval

**PR:** [PR URL]
**Branch:** [branch name]

**What happens next:**
1. ⏳ Human reviews PR in GitHub
2. ⏳ Human approves and merges
3. ✓ CI deploys to staging automatically
4. ⏳ Human approves production deploy
5. ✓ Production deployed

**After human merges the PR, run this command to cleanup:**
```
/close-issue-cleanup
```

Or to automatically cleanup when PR is merged, keep this session open.
Checking PR status every 30 seconds...
```

### Step 7: Poll for Approval and Merge

Poll for human approval with a bounded loop (max 60 iterations / ~30 min):

```bash
for i in $(seq 1 60); do
  REVIEW=$(gh pr view --json reviewDecision -q '.reviewDecision')
  STATE=$(gh pr view --json state -q '.state')

  if [ "$STATE" = "MERGED" ]; then
    echo "PR already merged!"
    break
  elif [ "$STATE" = "CLOSED" ]; then
    echo "PR was closed without merging."
    exit 1
  elif [ "$REVIEW" = "APPROVED" ]; then
    echo "PR approved! Merging..."
    gh pr merge --merge --delete-branch
    break
  fi

  echo "[$i/60] Review: $REVIEW | State: $STATE - waiting for approval..."
  sleep 30
done

if [ "$i" -eq 60 ]; then
  echo "Timed out waiting for approval after 30 minutes."
  echo "Run /close-issue again after PR is approved."
  exit 1
fi
```

### Step 8: Cleanup Worktree (After Merge Only)

**ONLY execute after confirming PR is merged:**

```bash
WORKTREE_PATH=$(pwd) && MAIN_REPO=$(git rev-parse --show-toplevel)/../$(basename $(git rev-parse --show-toplevel)) && cd "$MAIN_REPO" && git checkout main && git pull && git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true && echo "Cleanup complete"
```

### Step 9: Report Success

Output this message:

```
## Issue Closed Successfully ✓

All steps completed:
- ✓ Quality checks passed
- ✓ Changes committed and pushed
- ✓ PR created
- ✓ PR merged by human
- ✓ Branch deleted
- ✓ Worktree removed
- ✓ Back on main

Deployment is handled by GitHub Actions:
- Staging: Automatic after merge
- Production: Requires human approval in GitHub
```

---

## Error Handling

If any step fails:
1. Report the specific error with details
2. Suggest how to fix it
3. Do NOT proceed to the next step
4. Do NOT close the tab if workflow didn't complete

## Critical Rules

1. **Execute every bash block** - Do not just describe, actually run the commands
2. **Stop on errors** - Any failure stops the workflow
3. **Merge after approval** - Agent merges PR only after human review approval via branch protection
4. **No skipping** - Every step is mandatory
