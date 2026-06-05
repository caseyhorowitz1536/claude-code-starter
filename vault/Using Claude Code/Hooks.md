---
title: Hooks
tags: [using-claude-code, configuration]
source: https://code.claude.com/docs/en/hooks
---

# Hooks

> Hooks are actions that fire automatically on lifecycle events — the hard guardrails that `CLAUDE.md` guidance can't enforce.

## Why it matters
Unlike instructions in [[CLAUDE.md and Memory|CLAUDE.md]] (which Claude *usually*
follows), a hook runs deterministically — every time, no matter what. That makes
hooks the right tool for rules that **must** hold: block a dangerous command,
auto-format after every edit, or log what the agent did.

## How it works / how to use it
You configure hooks in `settings.json`. Each hook binds to an event such as:

- **PreToolUse** — before a tool runs (can block it).
- **PostToolUse** — after a tool runs (e.g. run a formatter).
- **SessionStart / Stop / Notification** — session lifecycle points.

A hook can run a shell command, call an HTTP endpoint, or inject a prompt. Keep
them fast — they run inline and slow hooks make every action feel sluggish.

## See also
[[CLAUDE.md and Memory]] · [[Permissions and Settings]] · [[Tips and Safety]] · [[Using Claude Code/Start Here|Back to index]]
