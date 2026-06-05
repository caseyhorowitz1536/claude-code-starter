---
title: Sessions and Resuming
tags: [using-claude-code, workflow]
source: https://code.claude.com/docs/en/quickstart
---

# Sessions and Resuming

> Every conversation is a session you can leave and come back to without losing context.

## Why it matters
Real work spans coffee breaks, meetings, and reboots. Because sessions persist,
you can stop mid-task and pick up exactly where you left off instead of
re-explaining everything.

## How it works / how to use it
Each session is stored locally as a JSONL transcript, scoped to the project
directory you ran it in. To resume:

```bash
claude -c          # continue the most recent session in this project
claude --resume    # pick an earlier session from a list
```

Sessions live on your machine, not in the cloud, so they're private to you. Start
a fresh session (just `claude`) when you want a clean context window — long
sessions accumulate context that can crowd out what matters.

## See also
[[The Agentic Loop]] · [[CLAUDE.md and Memory]] · [[Checkpoints and Rewind]] · [[Using Claude Code/Start Here|Back to index]]
