---
title: Statusline and Output Styles
tags: [using-claude-code, configuration]
source: https://code.claude.com/docs/en/statusline
---

# Statusline and Output Styles

> A customizable status line shows live context (directory, git branch, model) at the bottom of your session.

## Why it matters
At a glance you can confirm *where* you are and *what* you're using before you let
Claude act — which directory, which branch, which model. Small thing, big help for
avoiding "oops, wrong repo" moments.

## How it works / how to use it
Define a `statusLine` in `~/.claude/settings.json`. The `command` type runs a
shell command and prints its output as the status line:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash -c 'printf \"%s\" \"$(basename \"$PWD\")\"; b=$(git branch --show-current 2>/dev/null); [ -n \"$b\" ] && printf \" (%s)\" \"$b\"; true'"
  }
}
```

This starter installs exactly that line (directory + branch) when you don't
already have a `settings.json`. Output styles likewise let you tune how Claude
formats its responses to fit your workflow.

## See also
[[Permissions and Settings]] · [[Git and Commits]] · [[Hooks]] · [[Using Claude Code/Start Here|Back to index]]
