#!/bin/bash
# Track code modifications for smart quality gate detection
# Runs AFTER Write/Edit tools via PostToolUse hook

# Read hook input from stdin
input=$(cat)

# Get tool name from input
TOOL_NAME=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null)

# Use PPID for consistent session tracking across all hooks
# All hooks in a Claude session share the same parent process
SESSION_MARKER="/tmp/claude-modified-$PPID"

# Track if Write or Edit tools were used
if [[ "$TOOL_NAME" == "Write" ]] || [[ "$TOOL_NAME" == "Edit" ]]; then
  # Mark that code was modified this session
  echo "$(date +%s)" > "$SESSION_MARKER"
fi

# Always allow the tool to complete - this is a PostToolUse hook
exit 0
