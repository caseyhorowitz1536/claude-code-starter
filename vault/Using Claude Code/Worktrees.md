---
title: Worktrees
tags: [using-claude-code, workflow]
source: https://code.claude.com/docs/en/common-workflows
---

# Worktrees

> Git worktrees check out multiple branches into separate directories so you can run parallel sessions without conflicts.

## Why it matters
Normally one repo holds one checked-out branch at a time. Worktrees let you have
several branches live in parallel folders — so you (and multiple Claude sessions)
can work on different features at once without stashing, switching, or stepping on
each other.

## How it works / how to use it
Create a worktree for a branch in its own directory:

```bash
git worktree add ../myproject-feature-x feature-x
```

Now `../myproject-feature-x` is an independent working copy on `feature-x`. Open a
separate Claude session there and it works in isolation. Remove it when done:

```bash
git worktree remove ../myproject-feature-x
```

This pairs naturally with [[Subagents and Parallel Agents]] for running several
independent threads of work simultaneously.

## See also
[[Git and Commits]] · [[Subagents and Parallel Agents]] · [[Sessions and Resuming]] · [[Using Claude Code/Start Here|Back to index]]
