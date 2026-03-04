#!/bin/bash
# post-compact-reminder.sh
# Runs on: SessionStart (matcher: "compact")
# Outputs plain text injected into Claude's context immediately after compaction
# Customize this for your project — add your build commands, conventions, and key files
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# Find the most recent implementation plan (if you use them)
LATEST_PLAN=$(ls -t "$PROJECT_DIR/implementation-plans/"*.md 2>/dev/null | head -1)
PLAN_NAME=""
if [ -n "$LATEST_PLAN" ]; then
    PLAN_NAME=$(basename "$LATEST_PLAN")
fi

cat <<EOF
CONTEXT RESTORED AFTER COMPACTION:

== Active Plan ==
- Implementation plan: implementation-plans/$PLAN_NAME — READ THIS FILE to restore task context

== Build / Test Commands ==
- Build: [YOUR BUILD COMMAND HERE]
- Test: [YOUR TEST COMMAND HERE]
- Dev server: [YOUR DEV COMMAND HERE]

== Project Rules ==
- [ADD YOUR CRITICAL RULES HERE]
- [e.g., No pushes to main without approval]
- [e.g., Run tests before committing]

== Key Directories ==
- Session logs: session-logs/ (auto-saved by hooks)
- [ADD YOUR KEY DIRECTORIES HERE]

== Notes ==
- Session logs are auto-saved to session-logs/ directory
- Read the most recent session log if you need to restore context from before compaction
EOF
