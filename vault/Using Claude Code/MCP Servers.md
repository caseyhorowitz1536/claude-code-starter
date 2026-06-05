---
title: MCP Servers
tags: [using-claude-code, extensibility]
source: https://code.claude.com/docs/en/mcp
---

# MCP Servers

> MCP (Model Context Protocol) servers connect Claude Code to external tools and data — files, APIs, databases, and more.

## Why it matters
MCP is how Claude reaches beyond your repo. Connect a server and Claude gains new
tools it can call: query a database, read your notes, hit an internal API. It's
the standard plug for extending what the agent can see and do.

## How it works / how to use it
Register a server with the CLI:

```bash
claude mcp add --scope user <name> -- <command to start the server>
```

Check what's connected with `claude mcp get <name>` or `claude mcp list`. Scope
can be **user** (all projects) or **project** (just this repo).

This starter connects your Obsidian vault as an MCP server named
**`obsidian-vault`**, using the official filesystem server over a space-free
symlink — so Claude can read and write your notes (no API key, no Obsidian plugin
required). Try `claude mcp get obsidian-vault`, then ask Claude to summarize or
add a note. Build your own with the `mcp-builder` skill.

## See also
[[Slash Commands]] · [[Hooks]] · [[Tips and Safety]] · [[Using Claude Code/Start Here|Back to index]]
