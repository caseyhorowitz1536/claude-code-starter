---
title: The Agentic Loop
tags: [using-claude-code, concepts]
source: https://code.claude.com/docs/en/overview
---

# The Agentic Loop

> The core cycle Claude runs to get work done: gather context, take action, then verify.

## Why it matters
Understanding the loop demystifies what Claude is doing and shows you where to
intervene. Most "bad" results come from a wrong assumption in the gather step —
catch it early and the rest follows.

## How it works / how to use it
Each turn, Claude:

1. **Gathers context** — reads files, searches the repo, runs read-only commands.
2. **Acts** — edits files, runs builds, creates commits (asking first when needed).
3. **Verifies** — runs tests or checks output, then iterates if something's off.

You can interrupt at any time (press `Esc`) to redirect, add information, or stop.
For risky or large work, run the loop in [[Plan Mode]] so you approve the plan
before any edits happen.

## See also
[[Plan Mode]] · [[Sessions and Resuming]] · [[Checkpoints and Rewind]] · [[Using Claude Code/Start Here|Back to index]]
