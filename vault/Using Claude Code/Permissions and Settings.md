---
title: Permissions and Settings
tags: [using-claude-code, configuration]
source: https://code.claude.com/docs/en/settings
---

# Permissions and Settings

> Permission modes and a `settings.json` file control what Claude is allowed to do without asking.

## Why it matters
Permissions are the safety dial. Tighten them when working on something sensitive,
loosen them in a throwaway sandbox. Set them well and Claude stops nagging for
trivial reads while still pausing before anything risky.

## How it works / how to use it
There are four permission **modes**, cycled with `Shift+Tab`:

- **default** — asks before edits and most commands.
- **acceptEdits** — auto-approves file edits, still asks for shell commands.
- **plan** — read-only research; see [[Plan Mode]].
- **bypassPermissions** — no prompts at all (sandboxes only — see [[Tips and Safety]]).

Persist rules in `~/.claude/settings.json` (user scope, all projects) or
`.claude/settings.json` (project scope). An `allow`/`deny` list pre-approves or
blocks specific tools, e.g. allow `Bash(git status)` and deny `Bash(rm -rf:*)`.
Use `/permissions` to review the active rules.

## See also
[[Plan Mode]] · [[Hooks]] · [[Statusline and Output Styles]] · [[Tips and Safety]] · [[Using Claude Code/Start Here|Back to index]]
