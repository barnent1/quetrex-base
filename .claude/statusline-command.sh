#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')

# Get git branch (suppress errors if not in a git repo)
branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo "no-git")

# Detect if we're in a worktree
worktree_info=""
if [ -f "$cwd/.git" ]; then
    # We're in a worktree (git file instead of directory)
    # Extract worktree name from path
    worktree_name=$(basename "$cwd")
    worktree_info="🌳 $worktree_name"
elif [[ "$cwd" == *"/.worktrees/"* ]]; then
    # Alternative detection: check if path contains .worktrees
    worktree_name=$(basename "$cwd")
    worktree_info="🌳 $worktree_name"
fi

# Get short directory name
dir_name=$(basename "$cwd")

# Build status line with colors (using printf for ANSI codes)
if [ -n "$worktree_info" ]; then
    # In a worktree - highlight it in cyan
    printf "\033[36m%s\033[0m \033[33m%s\033[0m \033[90m%s\033[0m" "$worktree_info" "$branch" "$model"
else
    # Normal repo - show in green
    printf "\033[32m%s\033[0m \033[33m%s\033[0m \033[90m%s\033[0m" "$dir_name" "$branch" "$model"
fi
