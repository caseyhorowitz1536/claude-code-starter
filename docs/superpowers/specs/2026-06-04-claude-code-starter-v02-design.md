# claude-code-starter v0.2 — Design Spec

**Date:** 2026-06-04
**Owner:** Casey Horowitz (`caseyhorowitz1536`)
**Status:** Approved design — ready for implementation planning
**Builds on:** [`2026-06-03-claude-code-starter-design.md`](./2026-06-03-claude-code-starter-design.md) (v0.1, shipped)

## 1. Problem & Goal

v0.1 gets a newcomer from a fresh Mac to a working Claude Code + Obsidian setup
with a Karpathy LLM-theory vault and curated skills. Two gaps remain:

1. **Content gap** — the bundled vault teaches *LLM theory*, but nothing teaches
   the user how to actually **drive the tool they just installed** (skills, plan
   mode, hooks, MCP, subagents, settings). And the vault isn't *connected* to
   Claude Code — Claude can't read or update it without manual setup.
2. **Robustness gap** — the `curl | bash` path tracks a moving `main`, the piped
   `bootstrap.sh` can half-run on a truncated download, there's no
   trap-based cleanup or actionable failure messaging, and there's no
   post-install way to confirm everything actually worked.

v0.2 closes both, in five components, while preserving v0.1's core ethos:
**idempotent, never-clobber, dry-run-able, no admin/sudo, macOS-only, inspectable.**

**Success criteria (observable):** After a clean run on macOS, in addition to all
v0.1 guarantees:

- A unified Obsidian vault exists containing both the **Karpathy LLM Wiki** and a
  new **Using Claude Code** wiki, with a top-level `Start Here` MOC and a root
  `CLAUDE.md`.
- `claude mcp get obsidian-vault` shows a **connected** filesystem MCP server
  scoped to that vault — Claude can read and write the notes from any session.
- A conservative `~/.claude/settings.json` is present (only if the user had none).
- `setup.sh --verify` prints an all-green report (claude on PATH, plugins,
  vault, MCP, Node, settings) and exits 0.
- `bootstrap.sh` installs a **pinned release tag**, not moving `main`, and a
  truncated download is a no-op.

## 2. Locked Decisions

From the brainstorming session (2026-06-04). The three marked **(default)** were
chosen by Casey via "move faster" and may be revisited in spec review.

| Decision | Choice | Rationale |
|---|---|---|
| Scope of v0.2 | All five items: Using-CC vault · more skills+config · doctor/verify · curl\|bash hardening · vault↔Claude integration | Coherent single release; features of one installer, not independent subsystems |
| Packaging | **Extend the existing modular `lib/do_<area>()` pattern** | YAGNI — no manifest/pack system for a handful of items; new work = new `lib/*.sh` + tests |
| Vault layout **(default)** | **Unified vault** `~/Documents/Claude Code Starter/` with `Karpathy LLM Wiki/` + `Using Claude Code/` subfolders, root `CLAUDE.md` + `Start Here.md`; MCP points at the root | Cleanest product; one vault to open; one MCP allowed dir; additive (leaves any existing v0.1 `Karpathy LLM Wiki/` standalone path untouched) |
| Bootstrap pin **(default)** | **Pin to latest release tag** via `git ls-remote --sort=-v:refname`, overridable with `CCS_REF` env; fall back to `main` only if no tags exist | Removes moving-`main` integrity risk with no manual bumping; users get real releases |
| Starter `settings.json` **(default)** | **Safe permissions allow/deny + a statusline, NO model pin, NO hooks**; write only if absent | Won't surprise or constrain a new user's plan/model; always-on hooks are bad default UX |
| MCP server | **Official `@modelcontextprotocol/server-filesystem`** via `npx`, **user scope**, scoped to the vault only | No API key, no Obsidian community plugin, no running Obsidian; full read+write over markdown |
| MCP path handling | Point the server at a **space-free symlink** to the vault (`~/.claude-code-vault → ~/Documents/Claude Code Starter`) | Dodges the filesystem-server spaces-arg fragility (issue #2437) and the no-`~`-expansion gotcha; absolute, stable path |

## 3. Architecture

### 3.1 Repo layout (additions in **bold**)

```
claude-code-starter/
├── bootstrap.sh          # HARDENED: main()-wrapped, pinned tag, atomic clone, trap cleanup
├── setup.sh              # + --verify flag, + EXIT-trap cleanup, calls do_config/do_mcp/do_verify
├── lib/
│   ├── common.sh         # + need_cmd(), ensure(), fatal() helpers
│   ├── preflight.sh      # (unchanged) + optional node presence note
│   ├── claude-code.sh    # (unchanged)
│   ├── obsidian.sh       # (unchanged)
│   ├── plugins.sh        # + a few curated plugins appended to PLUGINS[]
│   ├── vault.sh          # vault dest → "Claude Code Starter"; copies unified structure
│   ├── config.sh         # NEW: install conservative ~/.claude/settings.json (write-if-absent)
│   ├── mcp.sh            # NEW: symlink + claude mcp add (filesystem server, user scope)
│   └── verify.sh         # NEW: do_verify — non-mutating health checks; powers --verify
├── vault/                # RESTRUCTURED: unified vault (see §4)
│   ├── CLAUDE.md
│   ├── Start Here.md
│   ├── Karpathy LLM Wiki/   # existing 31 notes moved here (links unaffected — Obsidian resolves by name)
│   ├── Using Claude Code/   # NEW ~18–20 notes + sub-MOC
│   └── .obsidian/
├── tools/check-vault-links.sh   # UPDATED: recurse subfolders
├── tests/                # + skip-flag matrix, network-failure sim, config/mcp/verify unit tests
├── .github/workflows/    # + idempotent double-run (ubuntu+macos), wired-in new tests
└── docs/superpowers/…    # this spec + the plan
```

### 3.2 New & changed component contracts

Each `lib/*.sh` keeps the v0.1 rules: one `do_<area>` function, idempotent,
non-destructive, dry-run-aware via `run`, no side effects on source.

- **common.sh (changed)** — add:
  - `need_cmd <cmd>` — `fatal` with an actionable message if a required command is missing.
  - `ensure <cmd...>` — run-or-`fatal` wrapper (rustup-style) for must-succeed steps.
  - `fatal <msg>` — `err` then `exit 1`.
  These are additive; existing helpers unchanged.

- **setup.sh (changed)** —
  - New `--verify` flag: source modules, run `do_verify` **only**, exit with its status.
  - `main()` installs a `trap cleanup EXIT` that removes a per-run tempdir and, on
    non-zero exit, prints *"setup failed (exit N). Nothing was left half-installed;
    re-running is safe."*
  - Flow becomes: `do_preflight → do_claude_code → do_obsidian → do_config →
    do_plugins → do_vault → do_mcp → do_verify(soft) → final_message`.
  - New skip flags: `--skip-config`, `--skip-mcp` (mirror the existing `--skip-*`).
  - Keep Bash 3.2 compatibility (no `declare -A`, `mapfile`, `${var^^}`).

- **config.sh `do_config` (new)** — install `~/.claude/settings.json` **only if it
  does not already exist** (protects a user's existing settings — never clobber,
  never overwrite). If present, log a skip and (optionally) print what we *would*
  have added. Content = the conservative starter config in §6. Depends on: nothing.

- **vault.sh `do_vault` (changed)** — `VAULT_DEST="${HOME}/Documents/Claude Code Starter"`.
  Copy the restructured `vault/` only if the dest is absent (never clobber). Open
  in Obsidian at the end as today. The old v0.1 `~/Documents/Karpathy LLM Wiki/`
  standalone vault, if present, is left untouched (additive). Depends on: nothing.

- **mcp.sh `do_mcp` (new)** — connect the vault to Claude Code:
  1. Require the vault to exist (the filesystem server refuses to start if its
     allowed dir is missing — issue #3232). If absent, skip with a clear message.
  2. `need`-check `npx`/Node. If absent, **skip gracefully** and print the exact
     `claude mcp add …` command plus a note to install Node ≥18 — never hard-fail
     (mirrors the `do_plugins` manual-fallback pattern).
  3. Create a space-free symlink `~/.claude-code-vault → <vault>` (idempotent).
  4. If `claude mcp get obsidian-vault` already succeeds, skip (idempotent).
     Else: `claude mcp add --scope user obsidian-vault -- npx -y
     @modelcontextprotocol/server-filesystem "$HOME/.claude-code-vault"`.
  5. Verify with `claude mcp get obsidian-vault`; on failure, print the manual command.
  Dry-run logs the intended commands. Depends on: `claude` on PATH, Node, vault present.

- **verify.sh `do_verify` (new)** — **non-mutating** checks, each printed as ✓/✗
  with a remediation hint on ✗:
  - `claude` on PATH (+ `--version`); `~/.local/bin` on PATH
  - Obsidian.app present (`/Applications` or `~/Applications`)
  - vault present at `~/Documents/Claude Code Starter` + symlink resolves
  - Node/`npx` present
  - MCP `obsidian-vault` registered & connected (`claude mcp get`)
  - each curated plugin present (`claude plugin list`)
  - `~/.claude/settings.json` present and valid JSON
  Returns non-zero if any **critical** check fails (claude / vault / mcp); plugin
  and settings gaps are warnings. Depends on: nothing (read-only).

### 3.3 bootstrap.sh (hardened)

```
curl -fsSL https://raw.githubusercontent.com/caseyhorowitz1536/claude-code-starter/main/bootstrap.sh | bash
```

Changes (all grounded in rustup/nvm/Homebrew practice):

- **Partial-pipe safety:** wrap the whole body in `main() { … }` invoked **only on
  the last line** (`main "$@"`). A truncated download defines functions and does
  nothing — the single most important `curl|bash` idiom.
- **Pinning:** resolve `REF="${CCS_REF:-$(git ls-remote --tags --refs --sort=-v:refname "$REPO_URL" 'v*' | head -1 | sed 's#.*/##')}"`;
  if empty (no tags yet), fall back to `main` with a warning. Clone with
  `--depth 1 --branch "$REF"`. Update path: `git fetch --depth 1 origin tag "$REF"
  && git checkout -q "$REF"` (sidesteps the `pull --ff-only` divergence failure).
- **Atomic clone + cleanup:** clone into a `mktemp -d` sibling, `trap 'rm -rf "$tmp"' EXIT`,
  then `mv` into `$DEST` on success — `$DEST` only appears when fully cloned.
- **Preflight:** `need_cmd git` with an `xcode-select --install` hint.
- Optional: publish the SHA256 of `bootstrap.sh` in the README so cautious users
  can verify before piping.

## 4. The unified vault

Repo `vault/` is restructured into one Obsidian vault with two wikis:

```
vault/
├── CLAUDE.md                 # workspace instructions (see below)
├── Start Here.md             # top MOC → both wikis
├── Karpathy LLM Wiki/        # the existing 31 notes + their indexes, moved verbatim
├── Using Claude Code/        # NEW notes (see §4.1) + a sub-MOC
└── .obsidian/                # existing config (graph view, core plugins)
```

Obsidian resolves `[[wikilinks]]` by note name across the whole vault, so moving
the Karpathy notes into a subfolder **does not break their links**. New notes use
the same conventions: YAML frontmatter (`title`, `tags`, `source`), a short
summary, the core idea, and dense `[[wikilinks]]`. New tag cluster: `#using-claude-code`.

**Root `CLAUDE.md`** (so running `claude` inside the vault, and the MCP server,
treat it as a real workspace): states this is a personal knowledge wiki of
markdown notes; conventions are wikilinks + frontmatter; Claude may read and
update notes and add new ones in the right folder, keeping links resolvable and
the relevant MOC updated; it must not delete notes without asking.

### 4.1 "Using Claude Code" notes (~18–20, <500 words each)

Grounded in current `code.claude.com/docs`:

- **Start Here (Using Claude Code)** — sub-MOC
- What is Claude Code · Installing & Starting · The Agentic Loop · Sessions &
  Resuming · CLAUDE.md & Memory · Permissions & Settings · Skills · Slash
  Commands · Plan Mode · Subagents & Parallel Agents · Hooks · MCP Servers ·
  Statusline & Output Styles · Git & Commits · Worktrees · Checkpoints & Rewind ·
  Background Tasks & Routines · Tips & Safety · Glossary

Each links to the official docs for deep dives and cross-links siblings
(e.g. *Sessions* ↔ *Context Window*, *CLAUDE.md* ↔ *Memory*, *Permissions* ↔
*Settings* ↔ *Hooks*).

## 5. Curated skills additions

The `do_plugins` mechanism (marketplaces + `PLUGINS[]`) is unchanged; v0.2 simply
**appends** a small, beginner-useful set. Candidate additions (exact list verified
for availability during planning): `skill-creator` (author your own skills) and
`mcp-builder` (build your own MCP servers) — both reinforce the new vault content.
Easy to edit; nothing else from the large finance/PE/gsd fleets is added.

## 6. Starter settings.json (write-if-absent)

Conservative, model-agnostic, hook-free. **Exact permission-rule syntax is
verified against the installed `claude` version during planning** (the `Bash(cmd
*)` vs `Bash(cmd:*)` form differs by version), so the snippet below is
representative:

```jsonc
{
  "permissions": {
    "allow": [
      "Bash(ls:*)", "Bash(cat:*)", "Bash(grep:*)", "Bash(rg:*)",
      "Bash(pwd)", "Bash(head:*)", "Bash(tail:*)", "Bash(find:*)",
      "Bash(which:*)", "Bash(git status)", "Bash(git log:*)", "Bash(git diff:*)"
    ],
    "deny": [
      "Bash(rm -rf:*)", "Bash(sudo:*)", "Bash(curl http:*)", "Bash(wget:*)"
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "<small script: cwd + git branch>"
  }
}
```

No `model`, no `hooks`, no `bypassPermissions`. If `~/.claude/settings.json`
exists, we **do not touch it**.

## 7. Non-goals (explicit)

- Still **macOS-only**; no Windows/Linux *runtime* support (CI runs Linux only for
  fast dry-run/unit jobs).
- Does **not** install/configure community Obsidian MCP servers (Local REST API +
  key + cert) — rejected for friction.
- Does **not** overwrite an existing `~/.claude/settings.json` or an existing vault.
- Does **not** auto-install Node (skips MCP gracefully if Node is absent).
- Does **not** push or publish releases automatically (tagging `v0.2.0` is a
  manual release step the plan documents).
- Does **not** authenticate the user (`/login` remains theirs).

## 8. Risks & research items

1. **Node absent on a fresh Mac** — `npx` may be missing; `do_mcp` must skip
   gracefully with manual instructions (resolved by design above).
2. **Filesystem-server reliability** — refuses to start if the allowed dir is
   missing (issue #3232) → register only after the vault exists; use a stable
   local symlink, never an external/network path.
3. **Permission-rule syntax drift** — verify `Bash(...)` pattern form against the
   installed `claude` at plan time; ship valid JSON either way.
4. **Write access is real power** — the MCP server can overwrite/move/delete
   inside the vault as the user. Scope to **only** the vault symlink; rely on
   Claude Code's per-op approval; recommend the vault be under git.
5. **Prompt-injection surface** — vault markdown is treated as input; our content
   is first-party so risk is low, but note it.
6. **"latest release tag" needs a tag to exist** — cut `v0.2.0` as part of
   release; until then bootstrap falls back to `main` with a warning.
7. **macOS Bash 3.2** — keep bootstrap/setup 3.2-safe; test under
   `macos-latest`'s `/bin/bash`, not just Homebrew bash.
8. **Tests must not touch the real machine** — sandbox `HOME=$(mktemp -d)` and
   PATH-stub `git`/`curl`/`claude`/`npx`; run mutating checks only in `--dry-run`.

## 9. Testing strategy (additions to v0.1)

- **Unit (plain-bash harness, zero deps):** 8-way `--skip-*` combination matrix;
  `do_config` write-if-absent (skips when a settings file exists); `do_mcp`
  command construction in dry-run (symlink + correct `claude mcp add` line);
  `do_verify` pass/fail logic with stubbed `claude`/`npx`.
- **Network-failure sim:** PATH-stub a failing `git` and run `bootstrap.sh`;
  assert nonzero exit, the underlying error surfaces, and **no partial clone** is
  left (trap cleanup worked).
- **Idempotent double-run:** CI job on **both** `ubuntu-latest` and `macos-latest`
  running `setup.sh --dry-run --yes` twice; second run completes cleanly and is a
  no-op.
- **Vault links:** `tools/check-vault-links.sh` recurses subfolders; asserts every
  `[[wikilink]]` resolves across both wikis and required MOCs exist.
- **Verify smoke:** `setup.sh --verify` runs in CI against a stubbed environment.
- bats-core remains optional polish; the plain-bash harness stays the default.

## 10. Uninstall / reversibility (delta)

README documents the additions: remove `~/Documents/Claude Code Starter/`; remove
the symlink `~/.claude-code-vault`; `claude mcp remove obsidian-vault`; the
starter `~/.claude/settings.json` is only ever created if you had none (a `.bak.N`
is kept if a future version ever backs one up). All v0.2 changes are add-only and
reversible; nothing deletes user data.
