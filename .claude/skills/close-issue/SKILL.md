---
name: close-issue
description: Complete git workflow - commit, PR, wait for human approval, cleanup
allowed-tools: Bash, Read
---

# Close Issue Workflow

Completes the git workflow: quality check, commit, push, create PR. Then waits for human approval before cleanup.

**CRITICAL:** This workflow does NOT auto-merge. Human must approve PR in GitHub. After human merges, this workflow cleans up the worktree and closes the tab.

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

### Step 3: Check for Linear Context

Read the context file to check for Linear issue linking:

```bash
cat .issue/context.json 2>/dev/null || echo "No context file"
```

Extract `linearIssueId` and `linearUrl` if present.

### Step 4: Stage and Commit

Execute (replace $ARGUMENTS with the commit message from user):

```bash
git add -A && git status
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

### Step 5: Push to Remote

Execute:

```bash
git push -u origin $(git branch --show-current)
```

### Step 6: Create PR (NO AUTO-MERGE)

Create PR with Linear linking if available:

```bash
gh pr create --title "$ARGUMENTS" --body "$(cat <<'EOF'
## Summary
[Description based on commit message and changes]

## Linear Issue
[If linearIssueId exists: "Closes LINEAR_ISSUE_ID"]
[If linearUrl exists: Link to LINEAR_URL]

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

**CRITICAL:** Do NOT run `gh pr merge`. Human must approve in GitHub.

### Step 7: Report and Wait for Human

Output this message:

```
## PR Created - Awaiting Human Approval

**PR:** [PR URL]
**Branch:** [branch name]
**Linear Issue:** [if applicable]

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

### Step 8: Poll for PR Merge (Optional Auto-Cleanup)

If the user wants to wait for merge, poll:

```bash
while true; do
  STATE=$(gh pr view --json state -q '.state')
  if [ "$STATE" = "MERGED" ]; then
    echo "PR has been merged!"
    break
  elif [ "$STATE" = "CLOSED" ]; then
    echo "PR was closed without merging."
    exit 1
  fi
  echo "PR state: $STATE - waiting for merge..."
  sleep 30
done
```

### Step 9: Cleanup Worktree (After Merge Only)

**ONLY execute after confirming PR is merged:**

```bash
WORKTREE_PATH=$(pwd) && MAIN_REPO=$(git rev-parse --show-toplevel)/../$(basename $(git rev-parse --show-toplevel)) && cd "$MAIN_REPO" && git checkout main && git pull && git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true && echo "Cleanup complete"
```

### Step 10: Report Success

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

Closing tab in 3 seconds...
```

### Step 11: Close Tab - ONLY AFTER SUCCESSFUL MERGE

**Execute ONLY if PR was merged:**

```bash
sleep 3 && wezterm cli kill-pane --pane-id $WEZTERM_PANE
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
3. **NEVER auto-merge** - Human must approve PR in GitHub
4. **Close tab ONLY after merge** - Step 11 only runs if PR is confirmed merged
5. **Link Linear issues** - Include Linear ID in PR body if available
6. **No skipping** - Every step is mandatory
