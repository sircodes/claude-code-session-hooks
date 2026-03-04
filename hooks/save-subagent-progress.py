#!/usr/bin/env python3
"""
save-subagent-progress.py
Runs on: SubagentStop
Reads the sub-agent's JSONL transcript and saves:
  - Task prompt (first human message, up to 3000 chars)
  - Final output (last assistant text, up to 10KB)
  - Tool call count
Output: subagent-progress/{timestamp}_{type}_{id}.md
"""
import json
import os
import sys
from datetime import datetime, timezone

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

agent_type = data.get("agent_type", "unknown")
agent_id = data.get("agent_id", "unknown")
session_id = data.get("session_id", "unknown")
cwd = data.get("cwd", ".")
agent_transcript_path = data.get("agent_transcript_path", "")

progress_dir = os.path.join(cwd, "subagent-progress")
os.makedirs(progress_dir, exist_ok=True)

short_agent = agent_id[:8] if len(agent_id) >= 8 else agent_id
timestamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
outfile = os.path.join(progress_dir, f"{timestamp}_{agent_type}_{short_agent}.md")

final_output = ""
task_prompt = ""
tool_count = 0

if agent_transcript_path and os.path.isfile(agent_transcript_path):
    try:
        with open(agent_transcript_path, "r", encoding="utf-8") as f:
            for line in f:
                try:
                    msg = json.loads(line.strip())
                except json.JSONDecodeError:
                    continue
                role = msg.get("role", "")
                content = msg.get("content", "")
                if role == "human" and not task_prompt:
                    if isinstance(content, list):
                        task_prompt = "\n".join(
                            c.get("text", "") for c in content if c.get("type") == "text"
                        )[:3000]
                    elif isinstance(content, str):
                        task_prompt = content[:3000]
                if role == "assistant":
                    if isinstance(content, list):
                        for c in content:
                            if c.get("type") == "tool_use":
                                tool_count += 1
                            if c.get("type") == "text":
                                final_output = c.get("text", "")[-10000:]
                    elif isinstance(content, str):
                        final_output = content[-10000:]
    except Exception:
        pass

now_utc = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
with open(outfile, "w", encoding="utf-8") as f:
    f.write(f"# Sub-Agent Progress: {agent_type} ({short_agent})\n")
    f.write(f"- **Agent Type:** {agent_type}\n")
    f.write(f"- **Agent ID:** {agent_id}\n")
    f.write(f"- **Session ID:** {session_id}\n")
    f.write(f"- **Timestamp:** {now_utc}\n")
    f.write(f"- **Tool Calls Made:** {tool_count}\n\n")
    f.write("## Task Prompt\n```\n")
    f.write(task_prompt or "(not captured)")
    f.write("\n```\n\n## Final Output (last ~10KB)\n```\n")
    f.write(final_output or "(not captured)")
    f.write("\n```\n")

print(f"SubagentStop: Saved {agent_type} ({short_agent}) -> {outfile}", file=sys.stderr)
