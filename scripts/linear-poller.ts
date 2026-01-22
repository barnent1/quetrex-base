/**
 * Linear Issue Poller
 *
 * Polls Linear API every 5 minutes for issues labeled "auto-process"
 * and triggers the /create-issue workflow for each new issue.
 *
 * Setup:
 * 1. Create a Linear API key: https://linear.app/settings/api
 * 2. Set environment variable: LINEAR_API_KEY
 * 3. Set environment variable: LINEAR_TEAM_ID (your team's key, e.g., "QTX")
 * 4. Set environment variable: PROJECT_PATH (path to quetrex-base repo)
 *
 * Run with:
 *   npx tsx scripts/linear-poller.ts
 *
 * Or with pm2:
 *   pm2 start scripts/linear-poller.ts --name linear-poller --interpreter npx --interpreter-args tsx
 */

import { execSync, spawn } from 'child_process'
import { existsSync, readFileSync, writeFileSync } from 'fs'
import { join } from 'path'

// Configuration
const POLL_INTERVAL_MS = 5 * 60 * 1000 // 5 minutes
const LINEAR_API_URL = 'https://api.linear.app/graphql'
const PROCESSED_ISSUES_FILE = join(
  process.env.HOME ?? '~',
  '.linear-poller-processed.json'
)

// Environment variables
const LINEAR_API_KEY = process.env.LINEAR_API_KEY
const LINEAR_TEAM_ID = process.env.LINEAR_TEAM_ID ?? 'QTX'
const PROJECT_PATH =
  process.env.PROJECT_PATH ?? '/Users/barnent1/Projects/quetrex-base'

interface LinearIssue {
  id: string
  identifier: string
  title: string
  description: string
  url: string
  labels: {
    nodes: Array<{ name: string }>
  }
}

interface ProcessedIssue {
  id: string
  identifier: string
  processedAt: string
  branch: string
}

function log(message: string): void {
  const timestamp = new Date().toISOString()
  console.log(`[${timestamp}] ${message}`)
}

function loadProcessedIssues(): Map<string, ProcessedIssue> {
  if (!existsSync(PROCESSED_ISSUES_FILE)) {
    return new Map()
  }
  const data = JSON.parse(readFileSync(PROCESSED_ISSUES_FILE, 'utf-8'))
  return new Map(Object.entries(data))
}

function saveProcessedIssues(processed: Map<string, ProcessedIssue>): void {
  const data = Object.fromEntries(processed)
  writeFileSync(PROCESSED_ISSUES_FILE, JSON.stringify(data, null, 2))
}

async function fetchLinearIssues(): Promise<LinearIssue[]> {
  if (!LINEAR_API_KEY) {
    throw new Error('LINEAR_API_KEY environment variable is required')
  }

  const query = `
    query AutoProcessIssues($teamId: String!) {
      issues(
        filter: {
          team: { key: { eq: $teamId } }
          labels: { name: { eq: "auto-process" } }
          state: { type: { nin: ["completed", "canceled"] } }
        }
        first: 50
      ) {
        nodes {
          id
          identifier
          title
          description
          url
          labels {
            nodes {
              name
            }
          }
        }
      }
    }
  `

  const response = await fetch(LINEAR_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: LINEAR_API_KEY,
    },
    body: JSON.stringify({
      query,
      variables: { teamId: LINEAR_TEAM_ID },
    }),
  })

  if (!response.ok) {
    throw new Error(`Linear API error: ${response.status}`)
  }

  const result = (await response.json()) as {
    data?: { issues?: { nodes?: LinearIssue[] } }
    errors?: Array<{ message: string }>
  }

  if (result.errors) {
    throw new Error(`Linear GraphQL error: ${result.errors[0].message}`)
  }

  return result.data?.issues?.nodes ?? []
}

async function updateLinearIssueLabel(
  issueId: string,
  removeLabel: string,
  addLabel: string
): Promise<void> {
  if (!LINEAR_API_KEY) return

  // First, get the label IDs
  const labelQuery = `
    query GetLabels($teamId: String!) {
      team(id: $teamId) {
        labels {
          nodes {
            id
            name
          }
        }
      }
    }
  `

  // This is a simplified version - in production you'd want to cache labels
  // For now, we'll use the Linear CLI or API to update labels
  log(`  Would update labels: -${removeLabel} +${addLabel}`)
}

function generateBranchName(identifier: string, title: string): string {
  const slug = title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 40)

  return `issue/${identifier.toLowerCase()}-${slug}`
}

function generateTabName(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 30)
}

async function triggerWorkflow(issue: LinearIssue): Promise<string> {
  const tabName = generateTabName(issue.title)
  const branchName = generateBranchName(issue.identifier, issue.title)
  const prTitle = `feat: ${issue.title.toLowerCase()}`

  log(`  Tab: ${tabName}`)
  log(`  Branch: ${branchName}`)

  // Navigate to project directory
  process.chdir(PROJECT_PATH)

  // Create worktree
  const worktreePath = `../worktrees/${tabName}`
  execSync(`git worktree add ${worktreePath} -b ${branchName}`, {
    stdio: 'inherit',
  })

  // Create .issue directory with context
  const issueDir = join(PROJECT_PATH, worktreePath, '.issue')
  execSync(`mkdir -p "${issueDir}"`)

  const context = {
    tabName,
    branchName,
    prTitle,
    description: issue.title,
    linearIssueId: issue.identifier,
    linearUrl: issue.url,
    createdAt: new Date().toISOString(),
    createdBy: 'Linear Poller (automated)',
    status: 'in-progress',
    instructions:
      'When complete, write to .issue/status.json with {"status": "completed", "lastUpdate": "<timestamp>", "summary": "<what you did>"}. The orchestrator will then run /close-issue.',
  }

  writeFileSync(
    join(issueDir, 'context.json'),
    JSON.stringify(context, null, 2)
  )

  // Also create requirements.md from the issue description
  const requirements = `# Requirements: ${issue.title}

## Source
- **Linear Issue:** [${issue.identifier}](${issue.url})
- **Created:** ${new Date().toISOString()}

## Problem Statement
${issue.description ?? issue.title}

## Acceptance Criteria
- [ ] Implementation matches issue description
- [ ] All tests pass
- [ ] Code reviewed

## Notes
This issue was automatically triggered from Linear.
`

  writeFileSync(join(issueDir, 'requirements.md'), requirements)

  // Spawn WezTerm tab
  const paneId = execSync(
    `wezterm cli spawn --cwd "${join(PROJECT_PATH, worktreePath)}" -- zsh`
  )
    .toString()
    .trim()

  // Wait a moment for the pane to initialize
  execSync('sleep 0.5')

  // Set tab title
  execSync(`wezterm cli set-tab-title --pane-id ${paneId} "${tabName}"`)

  // Start Claude in the new tab
  const claudeCommand = `claude --dangerously-skip-permissions "Read .issue/context.json to understand the task, then invoke the architect agent to analyze and plan."`
  execSync(`wezterm cli send-text --pane-id ${paneId} '${claudeCommand}\n'`)

  return branchName
}

async function poll(): Promise<void> {
  log('Polling Linear for auto-process issues...')

  const processedIssues = loadProcessedIssues()

  try {
    const issues = await fetchLinearIssues()
    log(`Found ${issues.length} issues with auto-process label`)

    for (const issue of issues) {
      if (processedIssues.has(issue.id)) {
        log(`  Skipping ${issue.identifier} (already processed)`)
        continue
      }

      log(`Processing: ${issue.identifier} - ${issue.title}`)

      try {
        // Update label to in-progress
        await updateLinearIssueLabel(issue.id, 'auto-process', 'in-progress')

        // Trigger the workflow
        const branch = await triggerWorkflow(issue)

        // Record as processed
        processedIssues.set(issue.id, {
          id: issue.id,
          identifier: issue.identifier,
          processedAt: new Date().toISOString(),
          branch,
        })
        saveProcessedIssues(processedIssues)

        log(`  Successfully started workflow for ${issue.identifier}`)
      } catch (error) {
        log(
          `  Error processing ${issue.identifier}: ${error instanceof Error ? error.message : 'Unknown error'}`
        )
      }
    }
  } catch (error) {
    log(
      `Error fetching issues: ${error instanceof Error ? error.message : 'Unknown error'}`
    )
  }
}

async function main(): Promise<void> {
  log('Linear Poller started')
  log(`Team ID: ${LINEAR_TEAM_ID}`)
  log(`Project Path: ${PROJECT_PATH}`)
  log(`Poll Interval: ${POLL_INTERVAL_MS / 1000}s`)

  if (!LINEAR_API_KEY) {
    log('WARNING: LINEAR_API_KEY not set - running in dry-run mode')
  }

  // Initial poll
  await poll()

  // Set up interval
  setInterval(() => {
    poll().catch((error) => {
      log(`Poll error: ${error instanceof Error ? error.message : 'Unknown'}`)
    })
  }, POLL_INTERVAL_MS)
}

main().catch(console.error)
