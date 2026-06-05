---
title: Git and Commits
tags: [using-claude-code, workflow]
source: https://code.claude.com/docs/en/common-workflows
---

# Git and Commits

> Claude can stage changes, write commit messages, and manage git for you — with your review at each step.

## Why it matters
Good git hygiene is tedious to do by hand and easy to skip. Claude handles the
mechanics (status, diffs, staging, messages) so you commit small and often,
keeping a clean, reversible history.

## How it works / how to use it
Ask in plain English: "commit this with a clear message" or "show me the diff
before we commit." Claude runs `git status`/`git diff`, summarizes the change,
proposes a message, and commits after you approve.

Good habits to ask for:

- Review the diff before committing — read what's actually staged.
- Commit frequently in small, logical chunks.
- Keep messages descriptive (what changed and why).

For risky operations, [[Permissions and Settings]] can require Claude to ask
first; [[Checkpoints and Rewind]] gives a separate, non-git undo for edits.

## See also
[[Worktrees]] · [[Checkpoints and Rewind]] · [[Permissions and Settings]] · [[Using Claude Code/Start Here|Back to index]]
