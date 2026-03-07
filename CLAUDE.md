# CLAUDE.md — claude-code-session-hooks

═══════════════════════════════════════════════════════
REPO DISAMBIGUATION — READ THIS FIRST
═══════════════════════════════════════════════════════

This is the PUBLIC hooks repo — shell scripts and settings only.
No .NET app code, no database, no Blazor.

  claude-code-session-hooks   Public repo — CC hook scripts, settings example, README
                               Path: /mnt/c/Users/sirco/source/repos/claude-code-session-hooks
                               GitHub: github.com/sircodes/claude-code-session-hooks (private)

  Medicaid-Laws-Expert        Main application repo (separate)
                               Path: /mnt/c/Users/sirco/source/repos/Medicaid-Laws-Expert

Do NOT run dotnet, EF migrations, or Docker commands in this repo.
There is no app to build here.

═══════════════════════════════════════════════════════
STANDING RULES — ALL SESSIONS
═══════════════════════════════════════════════════════

BRANCHING
  Every change gets a feature branch. Never commit directly to main.
  Naming: fix/description, feat/description, docs/description
  Merge with no-ff when merging feature → main.

SESSION LOG
  After each workstream, append one line to /mnt/c/Users/sirco/mle-daily-log.md:
    - [YYYY-MM-DD] [repo-name] [branch] — [what was completed]
  After ALL work in the session, append a DONE line:
    - [YYYY-MM-DD] DONE: [repo] [branch] — [comma-separated summary]
  Always append — never overwrite.

BACKGROUND TASKS
  At session start, list any inherited background tasks (from previous
  session or sub-agents). Kill any that are stale or no longer needed.
  Never leave orphan tasks running silently.

KILL SWITCHES
  Stop the current action and ask if:
  - A single step is taking 2x the expected duration
  - You have asked more than 5 clarifying questions in one session
  - Smoke test failures exceed 10 consecutive fails on the same test
  Do not retry the same failing command more than twice without diagnosing.

GIT RULES
  - Never include Co-Authored-By in commits (house rule)
  - Git identity: sircodes <sircodes@gmail.com>
  - All repos must be private on GitHub (sircodes account)
  - Push from WSL using SSH

WIP POLICY
  Never leave a session with uncommitted work unless explicitly told to.
  If context runs out mid-task, commit a WIP commit with prefix "wip: ".
  On session start, check for WIP commits and clean them up first.

SESSION-END CHECKLIST
  Before ending any session:
  1. All changed files committed and pushed
  2. Daily log updated (mle-daily-log.md)
  3. No orphan background tasks running
  4. CLAUDE.md Verification (see below) passed

CLAUDE.MD VERIFICATION
  At the start of each session, confirm you are reading the repo-root
  CLAUDE.md (this file), not .claude/CLAUDE.md or a worktree copy.
  Path for this repo: /mnt/c/Users/sirco/source/repos/claude-code-session-hooks/CLAUDE.md

═══════════════════════════════════════════════════════
REPO-SPECIFIC RULES
═══════════════════════════════════════════════════════

## Purpose

Hook scripts for Claude Code sessions:
- session-checkpoint.sh — Runs on Stop + SessionEnd. Extracts user messages + tool usage from JSONL -> structured Markdown log.
- pre-compact-checkpoint.sh — Runs before context compaction. Snapshots last ~3000 chars of conversation.
- post-compact-reminder.sh — Runs after compaction. Re-injects project context.
- save-subagent-progress.py — Runs on SubagentStop. Saves sub-agent task + output + tool count.
- statusline-command.sh — Status line script showing cwd [repo:branch].

## Degradation Tolerance (Critical)

All hook scripts MUST be degradation-tolerant:
- Use ERR trap -> exit 0 — never exit 1 from a hook
- Add explicit exit 0 at end of every script
- Timeouts set in settings.json: SessionStart/PreCompact=60000ms, Stop/SessionEnd=120000ms, SubagentStop=30000ms
- Root cause: CC's internal compaction can time out independently of hook execution.
  Hook-side exit 1 blocks compaction — graceful exit 0 allows CC to continue.

## Settings File

settings-example.json — reference settings for Claude Code hooks + timeout config.
Copy to .claude/settings.json in the target project.

## Branch Status

fix/degradation-tolerant-hooks — ERR trap + exit 0 improvements. May be unmerged to main.
Check with git branch before starting work.

## Shell

Scripts use bash (not fish) since CC hooks run in bash context.
README examples use bash syntax.
