---
title: Glossary
tags: [using-claude-code, reference]
source: https://code.claude.com/docs/en/overview
---

# Glossary

> Quick definitions of the core Claude Code terms.

## Terms
- **Agentic loop** — the gather-context → act → verify cycle Claude runs each turn.
  See [[The Agentic Loop]].
- **Context window** — the working memory of a session; everything Claude can
  currently "see." Long sessions fill it up; start fresh to clear it.
- **Model** — the underlying Claude model doing the reasoning (e.g. an Opus,
  Sonnet, or Haiku tier). Pick the model that fits the task's difficulty.
- **Tool** — a capability Claude can invoke (read a file, run a command, call an
  MCP server). Every action is a tool call.
- **Skill** — a reusable markdown workflow. See [[Skills]].
- **Subagent** — an isolated worker session with its own context. See
  [[Subagents and Parallel Agents]].
- **Hook** — an automatic action bound to a lifecycle event. See [[Hooks]].
- **MCP** — Model Context Protocol; the standard for connecting external tools and
  data. See [[MCP Servers]].
- **Session** — one resumable conversation, stored locally. See
  [[Sessions and Resuming]].
- **Checkpoint** — a pre-edit file snapshot you can rewind to. See
  [[Checkpoints and Rewind]].

## See also
[[Using Claude Code/Start Here|Back to index]]
