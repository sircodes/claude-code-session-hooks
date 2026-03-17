#!/bin/bash
# session-checkpoint.sh
# Runs on: Stop (async), SessionEnd
# Extracts user messages + tool usage from the JSONL transcript
# Writes structured Markdown log to session-logs/
# On SessionEnd: auto-commits and pushes the log to git
set -eu

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // "."')

LOG_DIR="$PROJECT_DIR/session-logs"
mkdir -p "$LOG_DIR"

SHORT_ID="${SESSION_ID:0:8}"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
OUTFILE="$LOG_DIR/${TIMESTAMP}_${SHORT_ID}.md"

# If transcript file is missing, write a minimal log and exit
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    cat > "$OUTFILE" <<EOF
# Session Checkpoint
- **Session ID:** $SESSION_ID
- **Event:** $HOOK_EVENT
- **Timestamp:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Note:** Transcript file not found at: $TRANSCRIPT_PATH
EOF
    exit 0
fi

# Extract user messages (first 5000 chars)
USER_MSGS=$(jq -r '
  select(.type == "user") |
  .message.content |
  if type == "string" then .
  elif type == "array" then map(select(.type == "text") | .text) | join("\n")
  else "" end
' "$TRANSCRIPT_PATH" 2>/dev/null | head -c 5000)

# Count tool usage by name (top 20)
TOOL_COUNTS=$(jq -r '
  select(.type == "assistant") |
  .message.content // [] |
  if type == "array" then .[] else empty end |
  select(.type == "tool_use") |
  .name
' "$TRANSCRIPT_PATH" 2>/dev/null | sort | uniq -c | sort -rn | head -20)

# Transcript size metrics
TOTAL_LINES=$(wc -l < "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")

ASSISTANT_BYTES=$(jq -r '
  select(.type == "assistant") |
  .message.content // [] |
  if type == "array" then .[] else empty end |
  select(.type == "text") |
  .text
' "$TRANSCRIPT_PATH" 2>/dev/null | wc -c)

# Write the session log
cat > "$OUTFILE" <<HEADER
# Session Log: $SHORT_ID
- **Session ID:** $SESSION_ID
- **Event:** $HOOK_EVENT
- **Timestamp:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Transcript lines:** $TOTAL_LINES
- **Assistant output:** ~$((ASSISTANT_BYTES / 1000))KB

## User Messages
\`\`\`
$USER_MSGS
\`\`\`

## Tool Usage
\`\`\`
$TOOL_COUNTS
\`\`\`
HEADER

# On SessionEnd: commit and push the log
if [ "$HOOK_EVENT" = "SessionEnd" ]; then
    cd "$PROJECT_DIR"
    if git status --porcelain "session-logs/" 2>/dev/null | grep -q .; then
        git add "session-logs/" 2>/dev/null || true
        git commit -m "Auto-save session log $SHORT_ID" --no-verify 2>/dev/null || true
        git push origin main 2>/dev/null || true
    fi

    # Auto-copy tracking files to outbox (safety net — fires even if session forgot)
    OUTBOX="$HOME/cc-io/outbox"
    mkdir -p "$OUTBOX" 2>/dev/null || true
    for f in BACKLOG.md MLE-WORKING-MEMORY.md cc-rules-header.txt \
              MLE-ARCHITECTURE-SNAPSHOT.md CLAUDE.md; do
        [ -f "$PROJECT_DIR/$f" ] && \
          cp "$PROJECT_DIR/$f" "$OUTBOX/$f" 2>/dev/null || true
    done
    [ -f "$PROJECT_DIR/.claude/claude.md" ] && \
      cp "$PROJECT_DIR/.claude/claude.md" "$OUTBOX/claude.md" 2>/dev/null || true
fi
