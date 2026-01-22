---
name: create-issue
description: Start a new issue workflow with worktree and agent team
argument-hint: [issue description]
allowed-tools: Bash, Read, Write
---

# Create Issue Workflow

Creates a git worktree, new terminal tab, and spawns the architect agent to begin work.

## Usage

```
/create-issue Add user preference settings
/create-issue Fix the login button not working
```

## Instructions

### Step 1: Parse or Ask for Description

If `$ARGUMENTS` is provided, use it as the issue description.

If no arguments, ask: "What issue are you solving? Describe it briefly."

### Step 2: Generate Names

From the description, generate:
- **Tab Name**: 2-4 words, kebab-case (e.g., `user-preferences`)
- **Branch Name**: `issue/<descriptive-name>` (e.g., `issue/add-user-preferences`)
- **PR Title**: Conventional commit format (e.g., `feat: add user preference settings`)

### Step 3: Create Worktree

```bash
# From the main repo directory
cd $(git rev-parse --show-toplevel)

# Create worktree with new branch
git worktree add ../worktrees/TAB_NAME -b BRANCH_NAME

# Create .issue directory for agent communication
mkdir -p ../worktrees/TAB_NAME/.issue
```

### Step 4: Create Context File

Create the context file with the updated schema that supports Linear integration:

```bash
cat > ../worktrees/TAB_NAME/.issue/context.json << 'EOF'
{
  "tabName": "TAB_NAME",
  "branchName": "BRANCH_NAME",
  "prTitle": "PR_TITLE",
  "description": "ISSUE_DESCRIPTION",
  "linearIssueId": null,
  "linearUrl": null,
  "prNumber": null,
  "status": "in-progress",
  "createdAt": "ISO_TIMESTAMP",
  "createdBy": "Glen Barnhardt with the help of Claude Code",
  "instructions": "When complete, write to .issue/status.json with {\"status\": \"completed\", \"lastUpdate\": \"<timestamp>\", \"summary\": \"<what you did>\"}. Then run /close-issue to create PR."
}
EOF
```

**Context Schema:**
| Field | Type | Description |
|-------|------|-------------|
| tabName | string | WezTerm tab name |
| branchName | string | Git branch name |
| prTitle | string | Pull request title |
| description | string | Issue description |
| linearIssueId | string\|null | Linear issue ID (e.g., "QTX-123") if from Linear |
| linearUrl | string\|null | Linear issue URL if from Linear |
| prNumber | number\|null | GitHub PR number after creation |
| status | string | Current status: "in-progress", "pr-created", "merged", "closed" |
| createdAt | string | ISO timestamp |
| createdBy | string | Attribution |
| instructions | string | Instructions for the agent |

### Step 5: Spawn Terminal Tab

```bash
PANE_ID=$(wezterm cli spawn --cwd ../worktrees/TAB_NAME -- zsh) && \
sleep 0.5 && \
wezterm cli set-tab-title --pane-id $PANE_ID "TAB_NAME"
```

### Step 6: Start Claude in New Tab

```bash
wezterm cli send-text --pane-id $PANE_ID $'claude --dangerously-skip-permissions "Read .issue/context.json to understand the task, then invoke the architect agent to analyze and plan."\n'
```

### Step 7: Report Success

```
## Issue Workflow Started

**Worktree:** ../worktrees/TAB_NAME
**Branch:** BRANCH_NAME
**Tab:** TAB_NAME

Branch `BRANCH_NAME` created by Glen Barnhardt with Claude Code

**Agent Workflow:**
1. Architect agent analyzes codebase and creates plan
2. Designer agent creates design system (for UI work)
3. Database Architect agent handles schema changes (if needed)
4. Developer agent implements changes
5. Test Writer agent creates tests
6. QA agent verifies quality
7. Use `/close-issue` to create PR (human approval required)

**Deployment Flow (after PR created):**
1. Human reviews and merges PR
2. Auto-deploy to staging
3. Human approves production deploy in GitHub
```

## Remote Entry Point: Linear

Issues can also be created automatically from Linear:

1. Partner creates issue in Linear with `auto-process` label
2. `scripts/linear-poller.ts` detects the issue
3. Poller creates worktree with `linearIssueId` and `linearUrl` in context
4. Agent workflow begins automatically
5. PR links back to Linear issue
6. After human merges, Linear issue is marked complete

See `scripts/linear-poller.ts` for the automation service.

## Notes

- The new tab runs in its own context, keeping this conversation clean
- All work happens on a feature branch, never on main
- Use `/close-issue` in the new tab to complete the workflow
- PR requires human approval - agents cannot auto-merge
- Deployment requires human approval via GitHub Environments
