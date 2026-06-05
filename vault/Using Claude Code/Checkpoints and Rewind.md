---
title: Checkpoints and Rewind
tags: [using-claude-code, workflow]
source: https://code.claude.com/docs/en/checkpointing
---

# Checkpoints and Rewind

> Claude snapshots your files before each edit so you can instantly rewind to an earlier state.

## Why it matters
When a change goes sideways, you don't have to manually undo it or dig through
git. Rewind jumps the conversation and your files back to before things went
wrong — a fast, low-stakes safety net that encourages experimentation.

## How it works / how to use it
Checkpoints are taken automatically before edits. To rewind, press `Esc Esc`
(double-escape) and choose a point to roll back to. Your files and the
conversation return to that state.

Two important caveats:

- Checkpoints are **not git** — they're a separate, local undo. Still commit real
  milestones with [[Git and Commits]].
- Rewind restores **files only**. It can't undo external side effects — a pushed
  commit, a sent email, a deleted cloud resource. See [[Tips and Safety]].

## See also
[[Git and Commits]] · [[Sessions and Resuming]] · [[Tips and Safety]] · [[Using Claude Code/Start Here|Back to index]]
