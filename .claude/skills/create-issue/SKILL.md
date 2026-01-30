---
name: create-issue
description: Create a git worktree and feature branch for new work
argument-hint: [issue description]
allowed-tools: Bash, AskUserQuestion
---

# Create Issue

Creates a git worktree and feature branch for isolated development.

## Usage

```
/create-issue Add user preference settings
/create-issue Fix the login button not working
```

## Instructions

### Step 1: Parse or Ask for Description

If `$ARGUMENTS` is provided, use it as the issue description.

If no arguments, ask: "What are you working on?"

### Step 2: Generate Names

From the description, generate:
- **Branch Name**: `issue/<descriptive-name>` (e.g., `issue/add-user-preferences`)
- **Worktree Dir**: `../worktrees/<descriptive-name>` (e.g., `../worktrees/add-user-preferences`)

Use lowercase kebab-case. Keep it short and descriptive.

### Step 3: Create Worktree

```bash
cd $(git rev-parse --show-toplevel)
git worktree add ../worktrees/ISSUE_NAME -b issue/ISSUE_NAME
```

### Step 4: Change into the Worktree

```bash
cd ../worktrees/ISSUE_NAME
```

### Step 5: Report Success

```
## Issue Started

**Worktree:** ../worktrees/ISSUE_NAME
**Branch:** issue/ISSUE_NAME

Branch `issue/ISSUE_NAME` created by Glen Barnhardt with Claude Code
```
