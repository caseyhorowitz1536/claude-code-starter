# First-run prompt

After `setup.sh` finishes, open a new terminal, run `claude`, log in with
`/login`, then paste the whole block below as your first message. Claude will
health-check the install, connect your Obsidian vault if it isn't already,
organize the vault into a working "second brain," and confirm every starter
skill is ready to use.

---

You are running inside a fresh Claude Code install created by the
**claude-code-starter** setup script. Do a full health check and finish the
setup. Work through the four stages below in order, fix anything broken as you
go, and end with a single ✅/⚠️/❌ checklist of every item. Never overwrite or
delete anything that already exists — if something is already set up, verify it
and move on.

**Stage 1 — Verify the core install.**
Confirm the `claude` CLI is on PATH (`which claude && claude --version`).
The one-line installer puts the starter repo at `~/.claude-code-starter`
(if you cloned it yourself, look under `~/Documents/GitHub/claude-code-starter`).
Run its built-in health check, `bash ~/.claude-code-starter/setup.sh --verify`,
and report its output. Also confirm Node 18+ is available
(`node --version && npx --version`) — the vault connection needs it; setup
installs it to `~/.local/node` if it was missing — and that
`~/.claude/settings.json` exists. If Node is missing, re-run the installer
(`bash ~/.claude-code-starter/setup.sh --yes`); it installs Node and connects
the vault automatically.

**Stage 2 — Make sure Obsidian is hooked up to Claude.**
Run `claude mcp get obsidian-vault`. If it's registered, test it for real: use
the obsidian-vault MCP tools to list the vault's top-level folders and read one
note, so we know it works end-to-end (a registered server can still fail to
start). If it is NOT registered, hook it up now:

1. Find the vault. The starter creates it at `~/Documents/Claude Code Starter`
   (there's also a symlink at `~/.claude-code-vault`). If that's missing, ask
   me whether I have an existing Obsidian vault I'd rather connect, and use
   that path instead.
2. Register it read+write, user scope:
   `claude mcp add --scope user obsidian-vault -- npx -y @modelcontextprotocol/server-filesystem@2026.8.31 "<vault path>"`
3. Tell me to restart this session if the new server doesn't appear, then
   re-test by listing the vault contents.

**Stage 3 — Organize the vault into a second brain.**
Once the vault is connected, set it up so every future Claude session can read
and write my working memory. Create (only if they don't already exist — never
move or rename the shipped **Karpathy LLM Wiki** or **Using Claude Code**
folders):

- `Home.md` — a dashboard note at the vault root linking to everything below,
  plus the two shipped wikis. Explain in one line each what every section is for.
- `Inbox/` — capture folder for raw ideas and unsorted notes. Anything I paste
  or mention that doesn't have a home yet goes here first.
- `Projects/` — one note per active project, each with: goal, current status,
  next actions, and open questions. Seed it with a `_TEMPLATE.md` showing that
  structure.
- `Sessions/` — dated session notes (`YYYY-MM-DD <topic>.md`). From now on, at
  the end of every substantial Claude session, write a short note here: what we
  did, what's unfinished, and exact next steps — so the next session can pick
  up cold.
- `Tasks.md` — one running task list at the root (open items with dates), and
  `Completed Work.md` — where finished items get moved with a completion date.
- `Reference/` — durable how-tos, decisions, and links worth keeping.

Then write the first entry: a session note in `Sessions/` recording what this
health check found, and add any fixes still pending to `Tasks.md`. Finally,
state the standing convention plainly so I can hold you to it: **read `Home.md`
and `Tasks.md` at the start of future sessions when relevant; write a session
note at the end of substantial ones.**

**Stage 4 — Verify all skills are downloaded and ready.**
Run `claude plugin list` and confirm all eight starter plugins are installed:
`superpowers`, `andrej-karpathy-skills`, `claude-code-setup`, `feature-dev`,
`pr-review-toolkit`, `commit-commands`, `hookify`, `skill-creator`.
For any that are missing, install them — marketplaces first if needed:

- `/plugin marketplace add anthropics/claude-plugins-official`
- `/plugin marketplace add obra/superpowers-marketplace`
- `/plugin marketplace add forrestchang/andrej-karpathy-skills`

then `/plugin install <name>@<marketplace>` for each missing one.
Prove the skills are actually loadable, not just listed: name 3–5 skills you
can see in your available-skills list (e.g. brainstorming, writing-plans,
test-driven-development) and give me a one-line "try this" example prompt for
each, so I know how to invoke them.

**Finish** with the full checklist: CLI ✅/❌, settings ✅/❌, Node ✅/❌,
vault connected + tested ✅/❌, second brain organized ✅/❌, each of the 8
plugins ✅/❌ — and a short "what to try next" list (start with the **Using
Claude Code** wiki in the vault).
