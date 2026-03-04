#!/bin/sh
# statusline-command.sh
# Shows cwd [repo:branch] in the Claude Code UI
# Add to settings.json:
#   "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }

cwd=$(pwd)
repo=$(git --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
repo_name=$(basename "$repo" 2>/dev/null)
branch=$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

if [ -n "$repo_name" ] && [ -n "$branch" ]; then
  printf "%s  [%s:%s]" "$cwd" "$repo_name" "$branch"
elif [ -n "$repo_name" ]; then
  printf "%s  [%s]" "$cwd" "$repo_name"
else
  printf "%s" "$cwd"
fi
