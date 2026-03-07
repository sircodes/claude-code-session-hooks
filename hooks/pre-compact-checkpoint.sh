#!/bin/bash
# pre-compact-checkpoint.sh
# Runs on: PreCompact
# Snapshots the last ~3000 chars of user messages before the context window is wiped
#
# IMPORTANT: Must exit 0 — failure must never block compaction.
# Uses an ERR trap instead of set -euo pipefail so any error is logged gracefully.

trap 'echo "[pre-compact-checkpoint] ERROR on line $LINENO — exiting 0 to allow compaction" >&2; exit 0' ERR

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""' 2>/dev/null || echo "")
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "unknown"' 2>/dev/null || echo "unknown")
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // "."' 2>/dev/null || echo ".")

LOG_DIR="$PROJECT_DIR/session-logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true

SHORT_ID="${SESSION_ID:0:8}"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
OUTFILE="$LOG_DIR/${TIMESTAMP}_${SHORT_ID}_precompact.md"

TOTAL_LINES=0
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    TOTAL_LINES=$(wc -l < "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
fi

RECENT_MSGS=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    RECENT_MSGS=$(jq -r 'select(.role == "human") | .content // "" | if type == "array" then map(select(.type == "text") | .text) | join("\n") else . end' "$TRANSCRIPT_PATH" 2>/dev/null | tail -c 3000 || echo "(could not extract messages)")
fi

cat > "$OUTFILE" <<MDEOF
# Pre-Compaction Checkpoint: $SHORT_ID
- **Session ID:** $SESSION_ID
- **Trigger:** $TRIGGER
- **Timestamp:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Transcript lines:** $TOTAL_LINES

## Recent User Messages (last ~3000 chars)
\`\`\`
$RECENT_MSGS
\`\`\`
MDEOF

exit 0
