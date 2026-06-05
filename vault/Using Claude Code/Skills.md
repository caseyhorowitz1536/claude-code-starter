---
title: Skills
tags: [using-claude-code, extensibility]
source: https://code.claude.com/docs/en/skills
---

# Skills

> Skills are reusable, on-demand workflows written in markdown that teach Claude how to do a specific task well.

## Why it matters
A skill packages your hard-won process — "how we write a PR," "how we build a
DCF" — so Claude follows it consistently every time, instead of you re-prompting.
They're shareable and version-controlled like any file.

## How it works / how to use it
A skill is a `SKILL.md` with a short description and a body of instructions.
Claude loads every skill's **description at startup** (cheap), then loads the full
**body only when the skill is actually used** — so you can have many skills
without bloating context.

Invoke one with its slash name (e.g. `/skill-name`), or just describe the task and
Claude picks the matching skill automatically. Author your own with the
`skill-creator` skill installed by this starter.

## See also
[[Slash Commands]] · [[Subagents and Parallel Agents]] · [[CLAUDE.md and Memory]] · [[Using Claude Code/Start Here|Back to index]]
