#!/bin/bash
# post-compact-reminder.sh
# Runs on: SessionStart (matcher: "compact")
# CRITICAL: Fires after context compaction when ALL rules context is lost.
# Must restore enough context for CC to operate safely.
# Exit 0 ALWAYS — never block CC from restarting after compaction.

trap 'exit 0' ERR

PROJECT_DIR="/mnt/c/Users/sirco/source/repos/Medicaid-Laws-Expert"

# Read current app version dynamically
CURRENT_VERSION=$(grep -r "\"5\." "$PROJECT_DIR/src" \
  --include="*.cs" 2>/dev/null | grep -iv "obj\|bin" | \
  grep -oP '5\.\d+' | head -1 2>/dev/null || echo "unknown")

# Read current worktrees
WORKTREES=$(git -C "$PROJECT_DIR" worktree list 2>/dev/null || echo "unknown")

# Read working memory (first 3000 chars)
WORKING_MEMORY=$(head -c 3000 "$PROJECT_DIR/MLE-WORKING-MEMORY.md" 2>/dev/null || \
  echo "(MLE-WORKING-MEMORY.md not found)")

cat <<'EOF_HEADER'
===============================================================
CONTEXT RESTORED AFTER COMPACTION — READ BEFORE ACTING
===============================================================

REPO: Medicaid-Laws-Expert (main app — C#, Blazor, PostgreSQL)
NOT ui-testing. NOT claude-code-session-hooks.

FULL RULES: cat /mnt/c/Users/sirco/source/repos/Medicaid-Laws-Expert/cc-rules-header.txt

=== CRITICAL RULES (apply immediately) ===

DEPLOY:
  Dev: bash run.sh up (always safe)
  OVH prod: ONLY when Ken explicitly says "deploy to prod" this session
  NEVER: bash run.sh up release

WORKTREE:
  Main worktree ALWAYS stays on main branch
  Feature work: ../medicaidlaws-{slug} dedicated worktrees only
  NEVER checkout feature branch in main worktree

PARALLEL SAFETY:
  NEVER run two prompts calling run.sh simultaneously

COMMITS:
  NEVER commit directly to main
  ALL merges go through ccrun merge prompts

VERSION:
  Feature sessions do NOT bump AppVersion.cs
  Bumps happen ONLY in merge prompts

VERIFY BEFORE BUILD:
  Check git log and BACKLOG.md before implementing anything
  git log --oneline --all | grep -i "{feature}"
  If already shipped: report and exit

DB:
  ALWAYS: -U medicaid -d medicaid_laws
  NEVER: postgres, mle
  Prod DB: 40.160.13.46 (OVH)

EOF_HEADER

echo "CURRENT APP VERSION: v$CURRENT_VERSION"
echo ""
echo "=== ACTIVE WORKTREES ==="
echo "$WORKTREES"
echo ""
echo "=== CURRENT STATE (MLE-WORKING-MEMORY.md) ==="
echo "$WORKING_MEMORY"
echo ""
echo "=== NEXT STEPS ==="
echo "1. cat cc-rules-header.txt for full rules"
echo "2. cat MLE-WORKING-MEMORY.md for complete current state"
echo "3. Read MLE-ARCHITECTURE-SNAPSHOT.md before any API calls"
echo "4. Then proceed with the task"
echo "==============================================================="

exit 0
