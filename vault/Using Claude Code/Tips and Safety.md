---
title: Tips and Safety
tags: [using-claude-code, safety]
source: https://code.claude.com/docs/en/security
---

# Tips and Safety

> A short checklist for using Claude Code powerfully without footguns.

## Why it matters
Claude can run commands and edit real files, so a few habits keep that power safe.
Most incidents come from over-broad permissions or trusting untrusted input.

## How it works / how to use it
- **Reserve `bypassPermissions` for sandboxes.** Skipping all prompts is fine in a
  throwaway VM or container, dangerous on your main machine. Default to asking.
- **Audit side effects.** [[Checkpoints and Rewind]] restores files, but it can't
  un-push a commit, un-send an email, or un-delete a cloud resource. Review before
  approving anything irreversible.
- **Treat untrusted content as input, not instructions.** A web page, issue, or
  file Claude reads might contain prompt-injection text trying to hijack the agent.
  Be cautious when Claude acts on content from sources you don't control.
- **Start in [[Plan Mode]]** for anything non-trivial — approve the plan first.
- **Scope MCP and permissions narrowly.** Grant the least access that gets the job
  done (see [[Permissions and Settings]] and [[MCP Servers]]).
- **Use [[Hooks]] for must-hold rules** — guidance in CLAUDE.md is advisory.

## See also
[[Permissions and Settings]] · [[Hooks]] · [[Checkpoints and Rewind]] · [[MCP Servers]] · [[Using Claude Code/Start Here|Back to index]]
