---
name: create-issue
description: Create a git worktree and tmux window for new work
argument-hint: <issue-id> <description>
allowed-tools: Bash, AskUserQuestion
---

# Create Issue Workflow

Creates a git worktree, ensures the project has an iTerm2 window via tmux,
opens a tab for the issue, and launches Claude in it.

## Usage

```
/create-issue DQ-1 Fix the login button
/create-issue AI-3 Add voice export feature
```

## Instructions

### Step 1: Parse Arguments

If `$ARGUMENTS` is provided, split into:
- **Issue ID**: first token (e.g., `DQ-1`)
- **Description**: remaining tokens (e.g., `Fix the login button`)

If no arguments, ask two questions:
1. "What is the issue ID?" (e.g., `DQ-1`)
2. "Describe the issue" (e.g., `Fix the login button`)

### Step 2: Generate Names

From issue ID and description, generate:
- **Tab name**: `ISSUE_ID : DESCRIPTION` (e.g., `DQ-1 : Fix the login button`)
- **Branch name**: `issue/ISSUE_ID-description-kebab-case` (e.g., `issue/DQ-1-fix-the-login-button`)
- **Worktree dir**: `ISSUE_ID-description-kebab-case` (e.g., `DQ-1-fix-the-login-button`)

The kebab-case portion is the description lowercased with spaces replaced by hyphens.

### Step 3: Detect Project

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel)
PROJECT_NAME=$(basename "$PROJECT_ROOT")
```

### Step 4: Ensure Project Has an iTerm2 Window

Check if the tmux session exists and has an active `-CC` client:

```bash
SESSION_EXISTS=$(tmux has-session -t "$PROJECT_NAME" 2>/dev/null && echo "yes" || echo "no")
CLIENT_COUNT=$(tmux list-clients -t "$PROJECT_NAME" 2>/dev/null | wc -l | tr -d ' ')
```

Handle three cases:

**Case A -- No session exists** (`SESSION_EXISTS` = "no"):

```bash
tmux new-session -d -s "$PROJECT_NAME" -c "$PROJECT_ROOT"
osascript <<EOF
tell application "iTerm2"
  activate
  set newWindow to (create window with default profile)
  tell current session of newWindow
    write text "tmux -CC attach -t $PROJECT_NAME"
  end tell
end tell
EOF
sleep 3
```

**Case B -- Session exists but no client** (`SESSION_EXISTS` = "yes", `CLIENT_COUNT` = "0"):

```bash
osascript <<EOF
tell application "iTerm2"
  activate
  set newWindow to (create window with default profile)
  tell current session of newWindow
    write text "tmux -CC attach -t $PROJECT_NAME"
  end tell
end tell
EOF
sleep 3
```

**Case C -- Session exists and client is attached** (`SESSION_EXISTS` = "yes", `CLIENT_COUNT` > 0):

No action needed. New windows will appear as tabs automatically.

### Step 5: Create Worktree

```bash
cd "$PROJECT_ROOT"
git worktree add "../worktrees/$WORKTREE_DIR" -b "$BRANCH_NAME"
WORKTREE_PATH=$(cd "../worktrees/$WORKTREE_DIR" && pwd)
```

### Step 6: Create Tab and Launch Claude

```bash
TAB_NAME="$ISSUE_ID : $DESCRIPTION"
WINDOW_ID=$(tmux new-window -t "$PROJECT_NAME" -n "$TAB_NAME" -c "$WORKTREE_PATH" -P -F '#{window_id}')
tmux send-keys -t "$WINDOW_ID" 'claude' Enter
```

Uses `#{window_id}` (e.g., `@42`) to target the window, avoiding
parsing issues with `:` in the tab name.

### Step 7: Report

```
## Issue Started

**Issue:** ISSUE_ID : DESCRIPTION
**Project:** PROJECT_NAME
**Worktree:** ../worktrees/WORKTREE_DIR
**Branch:** BRANCH_NAME
**tmux session:** PROJECT_NAME
**tmux tab:** ISSUE_ID : DESCRIPTION

Branch `BRANCH_NAME` created by Glen Barnhardt with Claude Code
```
