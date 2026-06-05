---
title: Subagents and Parallel Agents
tags: [using-claude-code, workflow]
source: https://code.claude.com/docs/en/sub-agents
---

# Subagents and Parallel Agents

> Subagents are isolated worker sessions Claude spawns to handle a piece of work, then report back a summary.

## Why it matters
A subagent gets its own fresh context window, so it can dig deep into a problem
without polluting your main conversation. Multiple subagents can run in parallel
on independent tasks, which is both faster and keeps your main session focused.

## How it works / how to use it
Claude uses the Task tool to launch a subagent with a focused instruction. The
subagent works on its own, then returns a concise result — you see the summary,
not its full transcript. This is ideal for:

- Searching a large codebase ("find everywhere X is used").
- Running several independent edits or investigations at once.
- Keeping heavy exploration out of your main context.

Just ask: "research these three modules in parallel" and Claude fans the work out.

## See also
[[The Agentic Loop]] · [[Plan Mode]] · [[Skills]] · [[Worktrees]] · [[Using Claude Code/Start Here|Back to index]]
