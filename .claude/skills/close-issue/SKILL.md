---
name: close-issue
description: Complete git workflow - commit, PR, merge, cleanup
allowed-tools: Bash, Read
---

# Close Issue Workflow

Completes the git workflow with **guaranteed cleanup**: quality check, commit, push, create PR, merge, remove worktree, and verify clean git state. If any mutation step fails, cleanup still runs.

**Two-Phase Design:**
- **Phase 1 (Sections 1-3):** Read-only. Nothing is mutated. Failure = stop and report.
- **Phase 2 (Sections 4-6):** Mutations. Once started, cleanup is MANDATORY regardless of outcome.

## Usage

```
/close-issue feat: add user preferences
/close-issue fix: resolve login button issue
```

## Instructions

Execute ALL sections in order. Do NOT skip any section.

---

### Section 1: Capture Context

Capture all context BEFORE any mutations. These values are used throughout the workflow.

```bash
BRANCH=$(git branch --show-current) && WORKTREE_PATH=$(pwd) && MAIN_REPO=$(git worktree list | head -1 | awk '{print $1}') && echo "BRANCH=$BRANCH" && echo "WORKTREE_PATH=$WORKTREE_PATH" && echo "MAIN_REPO=$MAIN_REPO"
```

**Guard:** If on main/master, STOP immediately:

```bash
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then echo "ERROR: Cannot close issue from main branch" && exit 1; fi
```

Record these values mentally. They are needed in Sections 4 and 5.

---

### Section 2: Pre-Cleanup (stale state from previous runs)

Clean up any stale state left by previous failed runs. This section is informational and never blocks the workflow.

```bash
git worktree prune 2>/dev/null; git remote prune origin 2>/dev/null; echo "Pre-cleanup complete"
```

Optionally report stale merged branches (informational only):

```bash
git branch --merged main 2>/dev/null | grep -v '^\*\|main\|master' || echo "No stale merged branches"
```

---

### Section 3: Quality Gates (fail = STOP, nothing to clean)

Run all quality checks. If ANY fail, STOP and report errors. No mutation has occurred, so no cleanup is needed.

**Type-check:**

```bash
npm run type-check
```

If type-check fails, STOP and report errors. Do NOT proceed.

**Lint:**

```bash
npm run lint 2>&1 | head -30
```

If lint has errors, STOP and report. Do NOT proceed.

**Tests:**

```bash
npm run test:run 2>&1 | tail -20
```

If tests fail, STOP and report. Do NOT proceed.

---

### Section 4: Mutation Phase (fail = skip to Section 5)

**CRITICAL AGENT INSTRUCTION:** From this point forward, if ANY step fails, **skip immediately to Section 5 (Mandatory Cleanup)**. Do NOT stop and report. Do NOT retry. Go directly to cleanup.

Track progress mentally using these markers:
- `COMMITTED` = false
- `PUSHED` = false
- `PR_CREATED` = false (and `PR_URL` = none)
- `MERGED` = false

#### 4a: Stage and Commit

Review what will be staged:

```bash
git status
```

Stage tracked changes:

```bash
git add -u
```

Review untracked files. Stage them explicitly by name only after verifying they belong in the commit (no `.env`, credentials, or temp files):

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

Commit:

```bash
git commit -m "$(cat <<'EOF'
$ARGUMENTS

Branch created by Glen Barnhardt with the help of Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

If commit succeeds, set `COMMITTED = true`. If it fails, **skip to Section 5**.

#### 4b: Push to Remote

```bash
git push -u origin $(git branch --show-current)
```

If push succeeds, set `PUSHED = true`. If it fails, **skip to Section 5**.

#### 4c: Create PR

```bash
gh pr create --title "$ARGUMENTS" --body "$(cat <<'EOF'
## Summary
[Description based on commit message and changes]

## Test Plan
- [x] Type check passes
- [x] Lint passes
- [x] Tests pass

---
Generated with Claude Code
EOF
)"
```

If PR creation succeeds, set `PR_CREATED = true` and record `PR_URL`. If it fails, **skip to Section 5**.

#### 4d: Merge PR

```bash
gh pr merge --merge --delete-branch
```

If merge succeeds, set `MERGED = true`. If it fails, **skip to Section 5**.

---

### Section 5: Mandatory Cleanup (ALWAYS runs after Section 4)

**This section ALWAYS executes after Section 4 starts, regardless of success or failure.**

Navigate to the main repository:

```bash
cd "$MAIN_REPO"
```

#### Remote Cleanup (conditional on progress)

Apply the FIRST matching condition:

- **MERGED = true:** Verify remote branch is gone. If it still exists, delete it:
  ```bash
  git push origin --delete "$BRANCH" 2>/dev/null || true
  ```

- **PR_CREATED = true but MERGED = false:** Leave the PR open. Report the PR URL for manual merge. Do NOT delete the remote branch (it would orphan the PR).

- **PUSHED = true but PR_CREATED = false:** Delete the orphaned remote branch:
  ```bash
  git push origin --delete "$BRANCH"
  ```

- **PUSHED = false:** No remote cleanup needed.

#### Local Cleanup (always runs)

```bash
git checkout main && git pull --prune
```

Remove the worktree:

```bash
git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true
```

Prune worktree refs:

```bash
git worktree prune
```

Delete the local branch (force-delete is safe because code passed QA and exists on remote or in reflog):

```bash
git branch -D "$BRANCH" 2>/dev/null || true
```

#### Final Verification

```bash
echo "=== Worktrees ===" && git worktree list && echo "" && echo "=== Local Branches ===" && git branch && echo "" && echo "=== Remote Branches ===" && git branch -r && echo "" && echo "=== Git Status ===" && git status
```

Verify:
- Only `main` worktree remains (plus any other active worktrees for other issues)
- The feature branch is gone from local branches
- The feature branch is gone from remote branches
- Working tree is clean on main

If stale remote refs remain:

```bash
git remote prune origin
```

---

### Section 6: Close tmux Window

After cleanup is complete, close the tmux window for this issue:

```bash
tmux kill-window
```

This is the last command. The tab closes when the issue is fully closed.

---

### Section 7: Report Outcome

Report one of the following based on what happened:

#### Success (all steps completed)

```
## Issue Closed

- Quality checks passed (type-check, lint, tests)
- Changes committed and pushed
- PR created and merged
- Remote branch deleted
- Worktree removed
- Local branch cleaned up
- On main, up to date
```

#### Partial Failure (mutation step failed, cleanup completed)

```
## Issue Partially Closed

**Failed at:** [step that failed, e.g., "Push to remote"]
**Error:** [error message]

**What was cleaned up:**
- [x] Worktree removed
- [x] Local branch deleted
- [x] Returned to main

**What the user needs to do:**
- [Specific action based on failure point]
```

Use the progress markers to determine the correct report:

| Failed Step | User Action |
|-------------|-------------|
| Commit failed | Re-run `/close-issue` after fixing the commit issue |
| Push failed | Check remote access, then re-run `/close-issue` |
| PR creation failed | Push exists; manually create PR or re-run `/close-issue` from a new worktree |
| Merge failed | PR is open at [PR_URL]; merge manually in GitHub |

---

## Critical Rules

1. **Execute every bash block** - Do not just describe, actually run the commands
2. **Phase 1 stops on error** - Quality gate failure = stop, no cleanup needed
3. **Phase 2 always cleans up** - Once mutations start, cleanup is mandatory
4. **Skip to Section 5 on mutation failure** - Never stop mid-mutation without cleaning up
5. **Force-delete local branch** - Use `-D` not `-d` since merge may not have completed
6. **Leave PR open if merge fails** - Deleting the remote branch would orphan the PR
7. **Delete remote branch if push succeeded but PR failed** - Orphaned branches get cleaned up
