---
title: CLAUDE.md and Memory
tags: [using-claude-code, configuration]
source: https://code.claude.com/docs/en/memory
---

# CLAUDE.md and Memory

> `CLAUDE.md` is a project file of standing instructions Claude reads as context at the start of every session.

## Why it matters
It's where you teach Claude your conventions once — build commands, code style,
"always run the linter," "never touch the prod config" — so you don't repeat
yourself each session. There's also automatic memory that persists notes across
conversations.

## How it works / how to use it
Run `/init` to generate a starter `CLAUDE.md` from your repo. Edit it like any
markdown file; you can also add a personal `~/.claude/CLAUDE.md` for instructions
that apply to every project. Use `/memory` to view or edit memory files.

Important: `CLAUDE.md` is loaded as **context, not as enforcement**. Claude reads
and generally follows it, but it's guidance, not a hard rule. For guardrails that
*must* hold (block a command, require a check), use [[Hooks]] or
[[Permissions and Settings]].

## See also
[[Hooks]] · [[Permissions and Settings]] · [[Installing and Starting]] · [[Using Claude Code/Start Here|Back to index]]
