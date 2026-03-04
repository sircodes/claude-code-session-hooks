# Claude Code Session Hooks

**Automatic session transcript capture, compaction recovery, and sub-agent progress tracking for Claude Code.**

Claude Code doesn't remember anything between sessions. Every crash, every disconnection, every context window compaction — gone. These hooks fix that.

## What This Does

Five hooks that run automatically during your Claude Code sessions:

| Hook | Trigger | What It Does |
|------|---------|-------------|
| **Session Checkpoint** | Every `Stop` + `SessionEnd` | Extracts user messages and tool usage from the raw JSONL transcript → writes a structured Markdown log |
| **Pre-Compact Checkpoint** | Before context compaction | Snapshots the last ~3,000 characters of conversation before the context window is wiped |
| **Post-Compact Reminder** | After compaction completes | Injects your active project context back into Claude's awareness — implementation plans, build rules, key procedures |
| **Sub-Agent Progress** | When any sub-agent finishes | Saves the sub-agent's task prompt, final output, and tool call count |
| **Auto-Commit Logs** | On `SessionEnd` | Commits and pushes session logs to git so they're preserved in your repo |

## What You Get

```
session-logs/
├── 2026-03-04_091523_a1b2c3d4.md          ← session checkpoint
├── 2026-03-04_093012_a1b2c3d4_precompact.md  ← pre-compaction snapshot
└── 2026-03-04_094501_a1b2c3d4.md          ← session end (auto-committed)

subagent-progress/
└── 2026-03-04_092200_task_e5f6g7h8.md     ← sub-agent final output
```

Each log includes:
- Session ID and timestamp
- User messages (first 5,000 characters)
- Tool usage counts (sorted by frequency)
- Transcript size and assistant output volume
- Pre-compaction snapshots of recent context

## Why This Matters

- **Session crashes mid-feature?** Open a new session, point it at the log: `"Read session-logs/2026-03-04_091523_a1b2c3d4.md and continue this work."` Zero loss.
- **Hit the token limit?** The pre-compact snapshot preserved what mattered. The post-compact reminder restores orientation. CC doesn't skip a beat.
- **Onboarding a new session on existing work?** The logs are in the repo. Full history, structured and readable.
- **Need to debug what CC actually did?** Tool usage counts, user messages, timestamps — it's all there.

## Installation

### 1. Copy hook scripts to your project

```bash
# From your project root
mkdir -p scripts/hooks
cp hooks/session-checkpoint.sh scripts/hooks/
cp hooks/pre-compact-checkpoint.sh scripts/hooks/
cp hooks/post-compact-reminder.sh scripts/hooks/
cp hooks/save-subagent-progress.py scripts/hooks/
chmod +x scripts/hooks/*.sh scripts/hooks/*.py
```

### 2. Add hooks to your Claude Code settings

Copy the hooks block from [`settings-example.json`](settings-example.json) into your project's `.claude/settings.json`.

If you don't have a `.claude/settings.json` yet:

```bash
mkdir -p .claude
cp settings-example.json .claude/settings.json
```

### 3. Customize the post-compact reminder

Edit `scripts/hooks/post-compact-reminder.sh` to reference your project's specifics:
- Your implementation plan directory (or remove that line)
- Your build command
- Your project-specific rules and procedures

This hook is the most project-specific — it's the one you'll want to tailor.

### 4. (Optional) Add log directories to .gitignore

If you don't want session logs committed to your repo, add:

```gitignore
session-logs/
subagent-progress/
```

But consider keeping them — they're a searchable engineering history of every session.

## Requirements

- **jq** — for parsing JSONL transcripts (`apt install jq` / `brew install jq`)
- **bash** — standard shell (macOS/Linux)
- **python3** — for the sub-agent hook (no external packages needed)
- **git** — for auto-commit on session end

## How It Works

### The JSONL Transcript

Claude Code writes a JSONL file during each session at a path provided via `transcript_path` in the hook's stdin payload. Each line is a JSON object with `type` (`user`, `assistant`, `tool_use`, `tool_result`) containing the full conversation.

The hooks read this file, extract the relevant content, and write structured Markdown logs.

### Hook Lifecycle

```
SessionStart ──→ [you work] ──→ Stop (checkpoint saved)
                                  │
                                  ├──→ [resume work] ──→ PreCompact (snapshot saved)
                                  │                         │
                                  │                         └──→ Compaction happens
                                  │                               │
                                  │                               └──→ SessionStart/compact
                                  │                                     (reminder injected)
                                  │
                                  └──→ SessionEnd (checkpoint saved + git push)
                                  
SubagentStop ──→ (sub-agent progress saved independently)
```

### What Each Script Receives

Every hook receives a JSON payload on stdin:

```json
{
  "session_id": "abc123...",
  "transcript_path": "/path/to/transcript.jsonl",
  "hook_event_name": "Stop|SessionEnd|PreCompact|SubagentStop",
  "cwd": "/path/to/project"
}
```

Sub-agent hooks also receive `agent_type`, `agent_id`, and `agent_transcript_path`.

## Customization

### Adjust capture limits

In `session-checkpoint.sh`:
- `head -c 5000` — controls how many characters of user messages are captured (default: 5,000)
- `head -20` — controls how many unique tools are listed (default: top 20)

In `pre-compact-checkpoint.sh`:
- `tail -c 3000` — controls the pre-compaction snapshot size (default: last 3,000 characters)

### Disable auto-commit

Remove or comment out the `git add/commit/push` block at the bottom of `session-checkpoint.sh` if you don't want automatic commits.

### Add more context to post-compact reminder

The `post-compact-reminder.sh` script outputs plain text that gets injected into Claude's context after compaction. Add anything Claude needs to know to resume work:
- Active implementation plans
- Build/test commands
- Project conventions
- Links to memory files or key documentation

## Bonus: Status Line

The repo includes a status line script that shows `cwd [repo:branch]` in the Claude Code UI. Add to your `settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/statusline-command.sh"
}
```

See [`hooks/statusline-command.sh`](hooks/statusline-command.sh) for the script.

## License

MIT — use it, modify it, share it.

## Author

Built by [Sir Codes](https://www.linkedin.com/in/systemsarchitect/) — 40 years of software engineering, currently building [Medicaid Laws Expert](https://medicaidlaws.app).
