---
title: Background Tasks and Routines
tags: [using-claude-code, workflow]
source: https://code.claude.com/docs/en/common-workflows
---

# Background Tasks and Routines

> Run long or detached work in the background, and schedule recurring agents that run on their own.

## Why it matters
Some jobs are slow (a long test suite, a build, a watch process) and shouldn't
block your conversation. Others should just happen on a schedule (a nightly check,
a morning summary). Background tasks and routines cover both without you babysitting.

## How it works / how to use it
- **Background tasks** — Claude can launch a long-running command detached, keep
  working with you, and surface the output when it finishes. Good for builds,
  servers, and watchers.
- **Routines** — schedule an agent to run on a cron-like cadence with `/schedule`.
  Use it for recurring automation ("every morning, summarize new issues").

Keep scheduled and detached work scoped and auditable — see [[Tips and Safety]]
for why unattended agents need careful permissions.

## See also
[[Subagents and Parallel Agents]] · [[Sessions and Resuming]] · [[Tips and Safety]] · [[Using Claude Code/Start Here|Back to index]]
