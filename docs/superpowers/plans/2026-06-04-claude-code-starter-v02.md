# claude-code-starter v0.2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Using Claude Code" wiki, a Claude↔vault MCP+workspace connection, a starter `settings.json`, a `--verify` doctor, and `curl|bash` hardening to the claude-code-starter installer — preserving its idempotent / never-clobber / dry-run / macOS-only / no-sudo ethos.

**Architecture:** Extend the existing modular `lib/do_<area>()` pattern. New modules `config.sh`, `mcp.sh`, `verify.sh`; hardened `bootstrap.sh` + `common.sh`; a restructured unified `vault/` (two wikis under one root with a `CLAUDE.md` workspace); the official `@modelcontextprotocol/server-filesystem` registered at user scope against a space-free symlink to the vault. Everything stays Bash-3.2-safe.

**Tech Stack:** Bash (macOS `/bin/bash` 3.2 compatible), the `claude` CLI (`plugin`, `mcp` subcommands), `npx` + `@modelcontextprotocol/server-filesystem`, the repo's dependency-free plain-bash test harness (`tests/run.sh`), GitHub Actions, Obsidian markdown.

**Spec:** `docs/superpowers/specs/2026-06-04-claude-code-starter-v02-design.md`

**Branch:** `feat/starter-v02` (already created).

**Wave order (dependencies):**
- Wave 1 (no deps): Task 1 (common.sh helpers), Task 2 (bootstrap hardening)
- Wave 2 (needs common.sh): Task 3 (config.sh), Task 4 (vault restructure), Task 5 (Using-CC notes), Task 6 (link-checker), Task 7 (plugins additions), Task 8 (vault.sh dest)
- Wave 3 (needs vault dest + common.sh): Task 9 (mcp.sh), Task 10 (verify.sh), Task 11 (setup.sh integration)
- Wave 4 (needs all): Task 12 (CI), Task 13 (README), Task 14 (release prep)

**Test conventions (this repo):** plain-bash harness. Add `test_*` functions to a `tests/test_*.sh` file; they're auto-discovered by `tests/run.sh`. Assertions: `assert_eq "$got" "$want" "label"`, `assert_contains "$haystack" "$needle" "label"`, `assert_ok "<cmd string>" "label"`. Modules are source-safe (no side effects at source time), so tests `source` them and call `do_*` directly. Sandbox side effects with `HOME="$(mktemp -d)"` and PATH-stubs. "Run the suite" everywhere means: `bash tests/run.sh`.

---

## Task 1: common.sh robustness helpers

**Files:**
- Modify: `lib/common.sh` (append after `confirm()`)
- Test: `tests/test_common.sh` (append)

- [ ] **Step 1: Write the failing tests** — append to `tests/test_common.sh`:

```bash
test_need_cmd_ok() {
  # a command that exists returns 0 and prints nothing fatal
  assert_ok "need_cmd ls" 'need_cmd passes for an existing command'
}
test_need_cmd_missing() {
  # a bogus command must make need_cmd exit non-zero (run in a subshell so it
  # doesn't kill the test runner) and mention the command name.
  local out rc
  out="$( ( need_cmd definitely_not_a_real_cmd_xyz ) 2>&1 )"; rc=$?
  assert_ok "[[ $rc -ne 0 ]]" 'need_cmd exits non-zero for a missing command'
  assert_contains "$out" 'definitely_not_a_real_cmd_xyz' 'need_cmd names the missing command'
}
test_ensure_propagates_failure() {
  local rc; ( ensure false ) >/dev/null 2>&1; rc=$?
  assert_ok "[[ $rc -ne 0 ]]" 'ensure exits non-zero when the command fails'
}
test_ensure_passes_through() {
  assert_ok "ensure true" 'ensure returns 0 when the command succeeds'
}
```

> Note: `tests/test_common.sh` already sources `lib/common.sh`. If it does not, add `source "$ROOT/lib/common.sh"` at the top (guarded so it isn't double-sourced).

- [ ] **Step 2: Run to verify failure**

Run: `bash tests/run.sh`
Expected: FAIL — `need_cmd: command not found` / `ensure: command not found`.

- [ ] **Step 3: Implement** — append to `lib/common.sh`:

```bash
# fatal MSG -> print red error to stderr and exit 1.
fatal() { err "$*"; exit 1; }

# need_cmd CMD -> fatal with an actionable hint if CMD is not on PATH.
need_cmd() {
  have "$1" && return 0
  case "$1" in
    git) fatal "'git' is required. Install Xcode Command Line Tools: xcode-select --install" ;;
    npx|node) fatal "'$1' is required (Node.js 18+). Install Node from https://nodejs.org, then re-run." ;;
    *) fatal "'$1' is required but was not found on PATH." ;;
  esac
}

# ensure CMD ARGS... -> run; fatal if it fails. For must-succeed mutating steps.
ensure() { "$@" || fatal "command failed: $*"; }
```

- [ ] **Step 4: Run to verify pass**

Run: `bash tests/run.sh`
Expected: PASS (all four new assertions `ok`).

- [ ] **Step 5: Commit**

```bash
git add lib/common.sh tests/test_common.sh
git commit -m "feat(common): add need_cmd/ensure/fatal helpers"
```

---

## Task 2: Harden bootstrap.sh (pin + atomic clone + partial-pipe safety)

**Files:**
- Modify: `bootstrap.sh` (full rewrite, same behavior + hardening)
- Test: `tests/test_bootstrap.sh` (create)

- [ ] **Step 1: Write the failing test** — create `tests/test_bootstrap.sh`:

```bash
# bootstrap.sh must (a) be source-safe: sourcing it defines functions but does
# NOT clone/exec; (b) surface a failing git as a non-zero exit with no partial
# clone left behind. We stub git on PATH so no network is touched.
test_bootstrap_is_source_safe() {
  # Sourcing must not invoke main (guarded by the BASH_SOURCE check). If it ran,
  # it would try to clone and fail here. We assert the function exists instead.
  ( BOOTSTRAP_NO_MAIN=1 source "$ROOT/bootstrap.sh"; declare -F main >/dev/null ) \
    && assert_eq 0 0 'bootstrap defines main() without running it' \
    || assert_eq 1 0 'bootstrap defines main() without running it'
}
test_bootstrap_git_failure_is_clean() {
  local stub home out rc
  stub="$(mktemp -d)"; home="$(mktemp -d)"
  printf '#!/usr/bin/env bash\necho "fatal: unable to access" >&2\nexit 128\n' > "$stub/git"
  chmod +x "$stub/git"
  out="$( HOME="$home" PATH="$stub:$PATH" CCS_REF="v0.0.0-test" bash "$ROOT/bootstrap.sh" 2>&1 )"; rc=$?
  rm -rf "$stub"
  assert_ok "[[ $rc -ne 0 ]]" 'bootstrap exits non-zero when git fails'
  assert_contains "$out" 'unable to access' 'bootstrap surfaces the git error'
  assert_ok "[[ ! -d \"$home/.claude-code-starter\" ]]" 'no partial clone dir left behind'
  rm -rf "$home"
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bash tests/run.sh`
Expected: FAIL — current `bootstrap.sh` runs top-to-bottom (not source-safe) and leaves no `main()`.

- [ ] **Step 3: Implement** — replace the entire contents of `bootstrap.sh`:

```bash
#!/usr/bin/env bash
# One-liner entrypoint:
#   curl -fsSL https://raw.githubusercontent.com/caseyhorowitz1536/claude-code-starter/main/bootstrap.sh | bash
# Thin bootstrap: clone/update an INSPECTABLE repo, then exec setup.sh. All heavy
# logic lives in the repo, not in this piped script. Pins to a release tag so a
# broken/compromised main HEAD never reaches users. Override with CCS_REF=<tag>.
set -euo pipefail

REPO_URL="https://github.com/caseyhorowitz1536/claude-code-starter.git"
DEST="${HOME}/.claude-code-starter"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 && return 0
  echo "'$1' is required (install Xcode Command Line Tools: xcode-select --install)" >&2
  exit 1
}

# Echo the newest vX.Y.Z tag, or empty if none / offline.
latest_ref() {
  git ls-remote --tags --refs --sort=-v:refname "${REPO_URL}" 'v*' 2>/dev/null \
    | head -1 | sed 's#.*/##'
}

main() {
  need_cmd git
  local ref; ref="${CCS_REF:-$(latest_ref)}"
  if [[ -z "${ref}" ]]; then
    echo "! No release tag found; falling back to 'main'." >&2
    ref="main"
  fi

  if [[ -d "${DEST}/.git" ]]; then
    echo "• Updating ${DEST} to ${ref}"
    git -C "${DEST}" fetch --depth 1 origin "${ref}"
    git -C "${DEST}" checkout -q "FETCH_HEAD"
  else
    local tmp; tmp="$(mktemp -d "${DEST}.XXXXXX")"
    # Clean up a partial clone on any failure; DEST only appears once fully cloned.
    trap 'rm -rf "${tmp}"' EXIT
    echo "• Cloning ${ref} into ${DEST}"
    git clone --depth 1 --branch "${ref}" "${REPO_URL}" "${tmp}"
    mv "${tmp}" "${DEST}"
    trap - EXIT
  fi

  exec bash "${DEST}/setup.sh" "$@"
}

# Only run main when executed (not sourced, and not when BOOTSTRAP_NO_MAIN is set
# for tests). main is invoked on the LAST line so a truncated pipe is a no-op.
if [[ "${BASH_SOURCE[0]}" == "${0}" && -z "${BOOTSTRAP_NO_MAIN:-}" ]]; then
  main "$@"
fi
```

> Note on `--branch "$ref"` with a tag: `git clone --branch` accepts a tag name. For the update path we `fetch <ref>` then checkout `FETCH_HEAD`, which works for both tags and `main` and avoids the `git pull --ff-only` divergence failure. When `ref` is a fixed tag the test passes `CCS_REF=v0.0.0-test` so the stubbed git is exercised before any real network call.

- [ ] **Step 4: Run to verify pass**

Run: `bash tests/run.sh`
Expected: PASS — both bootstrap tests `ok`.

- [ ] **Step 5: Commit**

```bash
git add bootstrap.sh tests/test_bootstrap.sh
git commit -m "feat(bootstrap): pin to release tag, atomic clone, partial-pipe safety"
```

---

## Task 3: config.sh — starter settings.json (write-if-absent)

**Files:**
- Create: `assets/claude-settings.json`
- Create: `lib/config.sh`
- Test: `tests/test_config.sh` (create)

- [ ] **Step 1: Create the asset** — `assets/claude-settings.json` (representative permission syntax; Task 11 verifies the exact form against the installed `claude`):

```json
{
  "permissions": {
    "allow": [
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(grep:*)",
      "Bash(rg:*)",
      "Bash(pwd)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(find:*)",
      "Bash(which:*)",
      "Bash(git status)",
      "Bash(git log:*)",
      "Bash(git diff:*)"
    ],
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(sudo:*)",
      "Bash(curl http:*)",
      "Bash(wget:*)"
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "bash -c 'printf \"%s\" \"$(basename \"$PWD\")\"; b=$(git branch --show-current 2>/dev/null); [ -n \"$b\" ] && printf \" (%s)\" \"$b\"; true'"
  }
}
```

- [ ] **Step 2: Write the failing tests** — create `tests/test_config.sh`:

```bash
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"
source "$ROOT/lib/config.sh"

test_config_writes_when_absent() {
  local home; home="$(mktemp -d)"
  ( HOME="$home" REPO_DIR="$ROOT" DRY_RUN=0 do_config ) >/dev/null 2>&1
  assert_ok "[[ -f \"$home/.claude/settings.json\" ]]" 'do_config creates settings.json when absent'
  # must be valid JSON we can grep for a known key
  assert_contains "$(cat "$home/.claude/settings.json")" 'permissions' 'settings.json has permissions'
  rm -rf "$home"
}
test_config_never_clobbers() {
  local home; home="$(mktemp -d)"
  mkdir -p "$home/.claude"
  printf '{"mine":true}' > "$home/.claude/settings.json"
  ( HOME="$home" REPO_DIR="$ROOT" DRY_RUN=0 do_config ) >/dev/null 2>&1
  assert_contains "$(cat "$home/.claude/settings.json")" 'mine' 'do_config leaves an existing settings.json untouched'
  rm -rf "$home"
}
```

- [ ] **Step 3: Run to verify failure**

Run: `bash tests/run.sh`
Expected: FAIL — `do_config: command not found`.

- [ ] **Step 4: Implement** — create `lib/config.sh`:

```bash
#!/usr/bin/env bash
# do_config: install a conservative starter ~/.claude/settings.json — ONLY if the
# user has none (never clobber). Requires common.sh sourced first; expects $REPO_DIR.

do_config() {
  step "Claude Code settings"
  local dest="${HOME}/.claude/settings.json"
  local src="${REPO_DIR}/assets/claude-settings.json"

  if [[ ! -f "$src" ]]; then warn "starter settings asset missing at ${src}"; return 0; fi
  if [[ -f "$dest" ]]; then
    ok "Existing ${dest} found — leaving it untouched"
    return 0
  fi
  info "Installing starter settings to ${dest}"
  run mkdir -p "${HOME}/.claude"
  run cp "$src" "$dest"
  ok "Starter settings installed (safe read-only allow-list + statusline; no model/hooks)"
}
```

- [ ] **Step 5: Run to verify pass**

Run: `bash tests/run.sh`
Expected: PASS — both config tests `ok`.

- [ ] **Step 6: Commit**

```bash
git add assets/claude-settings.json lib/config.sh tests/test_config.sh
git commit -m "feat(config): install conservative starter settings.json (write-if-absent)"
```

---

## Task 4: Restructure vault into one root with subfolders + workspace CLAUDE.md

**Files:**
- Move: `vault/*.md` → `vault/Karpathy LLM Wiki/`
- Create: `vault/CLAUDE.md`
- Create: `vault/Start Here.md`
- Create: `vault/Using Claude Code/` (empty dir placeholder; notes added in Task 5)

- [ ] **Step 1: Move the Karpathy notes into a subfolder (preserve history)**

```bash
cd /Users/caseyhorowitz/Documents/GitHub/claude-code-starter
mkdir -p "vault/Karpathy LLM Wiki"
git mv vault/*.md "vault/Karpathy LLM Wiki/"
mkdir -p "vault/Using Claude Code"
```

Verify: `ls "vault/Karpathy LLM Wiki" | wc -l` → 31; `vault/.obsidian` still at vault root.

> Wikilinks are unaffected: Obsidian resolves `[[Note Name]]` by name across the whole vault regardless of folder.

- [ ] **Step 2: Create the workspace `vault/CLAUDE.md`**

```markdown
# Claude Code Starter Vault — workspace notes

This is a personal Obsidian knowledge vault of plain markdown notes, connected to
Claude Code via the `obsidian-vault` MCP server (read + write).

## Two wikis
- **Karpathy LLM Wiki/** — LLM theory (Andrej Karpathy's zero-to-hero + overviews).
- **Using Claude Code/** — how to drive Claude Code itself.

## Conventions (follow these when editing)
- Every note has YAML frontmatter: `title`, `tags`, `source`.
- Link related notes with `[[wikilinks]]` (by note name; folders don't matter).
- New notes go in the matching wiki folder; update that folder's index/MOC.
- Keep notes concise (aim < 500 words); link out to source docs for depth.
- You may read, edit, and add notes. **Do not delete notes without asking.**
- `Start Here.md` is the top-level map of content.
```

- [ ] **Step 3: Create the top-level `vault/Start Here.md` MOC**

```markdown
---
title: Start Here
tags: [moc]
source: claude-code-starter
---

# Start Here

Welcome. This vault has two wikis:

## 🤖 [[Using Claude Code/Start Here|Using Claude Code]]
Learn to drive the tool you just installed — skills, plan mode, hooks, MCP, and more.

## 🧠 Karpathy LLM Wiki
Understand how LLMs work, from micrograd to GPT-2.
- [[Start Here|Karpathy: Start Here]] · [[Zero-to-Hero Index]] · [[LLM Index]]

> This vault is connected to Claude Code (MCP server `obsidian-vault`). Ask Claude
> to summarize a note, add one, or link concepts together.
```

> Note: the existing Karpathy `Start Here.md` (now at `vault/Karpathy LLM Wiki/Start Here.md`) keeps its own title; the alias `[[Start Here|Karpathy: Start Here]]` disambiguates in the link text. If Obsidian's "by name" resolution is ambiguous between the two `Start Here` notes, Task 6's link-checker will flag it; if flagged, rename the Karpathy one to `Karpathy — Start Here.md` via `git mv` and update references.

- [ ] **Step 4: Commit**

```bash
git add -A vault
git commit -m "refactor(vault): unify into root + Karpathy LLM Wiki/ subfolder, add CLAUDE.md + top MOC"
```

---

## Task 5: Author the "Using Claude Code" notes

**Files:**
- Create: `vault/Using Claude Code/Start Here.md` + 18 concept notes (list below)

This task authors prose content (not code), so it follows a **template + worked
example + exact list + link map** rather than embedding 19 full notes. Author each
note to the template, grounded in the spec's §4.1 outline and the official docs at
`https://code.claude.com/docs`.

**Frontmatter + structure template (every note):**

```markdown
---
title: <Note Title>
tags: [using-claude-code, <one-or-two-topic-tags>]
source: https://code.claude.com/docs/<page>
---

# <Note Title>

> One-sentence definition.

## Why it matters
2-4 sentences.

## How it works / how to use it
Tight explanation, a tiny command or config example if useful.

## See also
[[Sibling Note A]] · [[Sibling Note B]] · [[Using Claude Code/Start Here|Back to index]]
```

- [ ] **Step 1: Write the sub-MOC** — `vault/Using Claude Code/Start Here.md`:

```markdown
---
title: Using Claude Code — Start Here
tags: [using-claude-code, moc]
source: https://code.claude.com/docs/en/overview
---

# Using Claude Code — Start Here

A beginner's map to driving Claude Code.

## First steps
[[What is Claude Code]] · [[Installing and Starting]] · [[The Agentic Loop]] · [[Sessions and Resuming]]

## Make it yours
[[CLAUDE.md and Memory]] · [[Permissions and Settings]] · [[Statusline and Output Styles]]

## Power features
[[Skills]] · [[Slash Commands]] · [[Plan Mode]] · [[Subagents and Parallel Agents]] · [[Hooks]] · [[MCP Servers]]

## Working with code
[[Git and Commits]] · [[Worktrees]] · [[Checkpoints and Rewind]] · [[Background Tasks and Routines]]

## Reference
[[Tips and Safety]] · [[Glossary]]
```

- [ ] **Step 2: Write one worked example note** — `vault/Using Claude Code/Plan Mode.md`:

```markdown
---
title: Plan Mode
tags: [using-claude-code, workflow]
source: https://code.claude.com/docs/en/quickstart
---

# Plan Mode

> A read-only mode where Claude researches and proposes a plan you approve before any file is changed.

## Why it matters
For anything non-trivial, planning first catches wrong assumptions before they
turn into wrong edits. You stay in control: nothing is written until you say so.

## How it works / how to use it
Press `Shift+Tab` to cycle permission modes until you reach **plan**. Claude can
read files and run read-only commands, then presents a plan. Approve it to switch
to execution, or send feedback to revise.

## See also
[[Permissions and Settings]] · [[The Agentic Loop]] · [[Subagents and Parallel Agents]] · [[Using Claude Code/Start Here|Back to index]]
```

- [ ] **Step 3: Author the remaining 17 notes** to the template, each in `vault/Using Claude Code/`. Exact filenames (so `[[wikilinks]]` resolve):

```
What is Claude Code.md
Installing and Starting.md
The Agentic Loop.md
Sessions and Resuming.md
CLAUDE.md and Memory.md
Permissions and Settings.md
Skills.md
Slash Commands.md
Subagents and Parallel Agents.md
Hooks.md
MCP Servers.md
Statusline and Output Styles.md
Git and Commits.md
Worktrees.md
Checkpoints and Rewind.md
Background Tasks and Routines.md
Tips and Safety.md
Glossary.md
```

Content guidance per note (keep each accurate to current docs, <500 words):
- **What is Claude Code** — agentic terminal coding assistant; also IDE/desktop/web; links Agentic Loop, Installing.
- **Installing and Starting** — `curl -fsSL https://claude.ai/install.sh | bash`; `claude`; `/login`; `/help`, `/init`.
- **The Agentic Loop** — gather context → act → verify; interrupt/steer anytime.
- **Sessions and Resuming** — local JSONL per project; `claude -c`, `claude --resume`.
- **CLAUDE.md and Memory** — project instructions file; auto memory; loaded as context not enforcement → link Hooks for enforcement.
- **Permissions and Settings** — modes (default/acceptEdits/plan/bypassPermissions); allow/deny in `settings.json`; user vs project scope.
- **Skills** — on-demand markdown workflows; `/name`; descriptions load at startup, body on use.
- **Slash Commands** — built-ins (`/init`, `/resume`, `/permissions`, `/memory`); custom via plugins.
- **Subagents and Parallel Agents** — Task tool spawns isolated workers with fresh context; return summaries; good for parallel/independent work.
- **Hooks** — shell/HTTP/prompt actions on lifecycle events (PreToolUse/PostToolUse/SessionStart…); hard guardrails; keep them fast.
- **MCP Servers** — connect external tools/data; `claude mcp add`; this vault is connected via `obsidian-vault`.
- **Statusline and Output Styles** — custom status command in settings.json.
- **Git and Commits** — Claude can stage/commit; review diffs; commit frequently.
- **Worktrees** — isolate branches into separate dirs for parallel sessions.
- **Checkpoints and Rewind** — pre-edit snapshots; `Esc Esc` to rewind; not git; doesn't cover external side effects.
- **Background Tasks and Routines** — long/detached tasks; `/schedule` routines.
- **Tips and Safety** — bypassPermissions only in sandboxes; audit side effects; treat untrusted content as input (prompt injection).
- **Glossary** — agentic loop, context window, model, tool, skill, subagent, hook, MCP, session, checkpoint.

- [ ] **Step 4: Commit**

```bash
git add -A "vault/Using Claude Code"
git commit -m "content(vault): add 'Using Claude Code' beginner wiki (19 notes)"
```

---

## Task 6: Make the vault link-checker recurse subfolders

**Files:**
- Modify: `tools/check-vault-links.sh`
- Test: run the tool against the restructured vault (the check IS the test)

- [ ] **Step 1: Read the current checker**

Run: `cat tools/check-vault-links.sh`
Goal: find where it enumerates notes (likely a flat `vault/*.md`) and where it lists targets.

- [ ] **Step 2: Make enumeration recursive** — change any flat glob to a recursive find. Replace the note-collection line(s) with:

```bash
# All markdown notes anywhere under the vault (one per line, NUL-safe).
find "${VAULT_DIR}" -name '.obsidian' -prune -o -type f -name '*.md' -print
```

And build the set of valid link targets from **basename without extension** (Obsidian resolves links by name), e.g.:

```bash
# valid targets = note basenames sans .md (handles links that omit the folder)
while IFS= read -r f; do
  base="$(basename "$f" .md)"
  VALID["$base"]=1
done < <(find "${VAULT_DIR}" -name '.obsidian' -prune -o -type f -name '*.md' -print)
```

> If the current script avoids associative arrays for Bash 3.2 safety, keep that style: collect basenames into a newline string and test membership with a `grep -Fxq` against it instead of `VALID[...]`. Match the existing script's idiom.

When parsing `[[Target|alias]]` or `[[Folder/Target]]`, strip the `|alias` and any `Folder/` prefix before checking membership, so folder-qualified links (used in the MOCs) validate against basenames.

- [ ] **Step 3: Run the checker**

Run: `bash tools/check-vault-links.sh`
Expected: PASS — no dangling links across both wikis. If the two `Start Here` notes collide, apply the rename noted in Task 4 Step 3 and re-run.

- [ ] **Step 4: Commit**

```bash
git add tools/check-vault-links.sh vault
git commit -m "fix(tools): recurse subfolders + handle folder/alias links in vault link checker"
```

---

## Task 7: Append curated plugins

**Files:**
- Modify: `lib/plugins.sh` (the `PLUGINS` array)

- [ ] **Step 1: Verify availability of the candidates**

Run (in a real Claude session or with the CLI logged in):
```bash
claude plugin marketplace add anthropics/claude-plugins-official 2>/dev/null || true
claude plugin install skill-creator@claude-plugins-official --scope user --help 2>&1 | head -1 || true
```
Confirm `skill-creator` and `mcp-builder` exist in a registered marketplace. If a name differs or is unavailable, adjust the entry (or drop it) — do not add a plugin that doesn't resolve.

- [ ] **Step 2: Append to the `PLUGINS` array** in `lib/plugins.sh` (only the verified entries):

```bash
  "skill-creator@claude-plugins-official"
  "mcp-builder@claude-plugins-official"
```

- [ ] **Step 3: Verify dry-run lists them**

Run: `bash setup.sh --dry-run --yes --skip-obsidian --skip-vault 2>&1 | grep -E 'skill-creator|mcp-builder'`
Expected: both appear in the `[dry-run] claude plugin install …` output.

- [ ] **Step 4: Commit**

```bash
git add lib/plugins.sh
git commit -m "feat(plugins): add skill-creator + mcp-builder to the curated set"
```

---

## Task 8: Point vault.sh at the unified vault

**Files:**
- Modify: `lib/vault.sh`
- Test: `tests/test_vault.sh` (create)

- [ ] **Step 1: Write the failing test** — create `tests/test_vault.sh`:

```bash
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"
source "$ROOT/lib/vault.sh"

test_vault_dest_is_unified_name() {
  assert_contains "$VAULT_DEST" 'Claude Code Starter' 'VAULT_DEST points at the unified vault'
}
test_vault_installs_then_skips() {
  local home; home="$(mktemp -d)"
  # ASSUME_YES so the "open in Obsidian?" confirm never blocks; no Obsidian present anyway.
  ( HOME="$home" REPO_DIR="$ROOT" DRY_RUN=0 ASSUME_YES=1 do_vault ) >/dev/null 2>&1
  assert_ok "[[ -f \"$home/Documents/Claude Code Starter/Start Here.md\" ]]" 'vault copied with top MOC'
  assert_ok "[[ -d \"$home/Documents/Claude Code Starter/Karpathy LLM Wiki\" ]]" 'Karpathy subfolder present'
  # second run must not error and must not duplicate
  ( HOME="$home" REPO_DIR="$ROOT" DRY_RUN=0 ASSUME_YES=1 do_vault ) >/dev/null 2>&1
  assert_eq "$?" 0 'second do_vault run is a clean no-op'
  rm -rf "$home"
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bash tests/run.sh`
Expected: FAIL — `VAULT_DEST` still says `Karpathy LLM Wiki`.

- [ ] **Step 3: Implement** — in `lib/vault.sh` change the destination and the `step`/messages:

```bash
VAULT_DEST="${HOME}/Documents/Claude Code Starter"
```

Update `step "Karpathy LLM Wiki vault"` → `step "Obsidian vault"` and any user-facing message that names the old path. The copy logic (`cp -R "$src" "$VAULT_DEST"` when absent, never clobber, optional `open -a Obsidian`) is unchanged and already copies the whole restructured `vault/`.

- [ ] **Step 4: Run to verify pass**

Run: `bash tests/run.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/vault.sh tests/test_vault.sh
git commit -m "feat(vault): install unified vault to ~/Documents/Claude Code Starter"
```

---

## Task 9: mcp.sh — connect the vault to Claude Code

**Files:**
- Create: `lib/mcp.sh`
- Test: `tests/test_mcp.sh` (create)

- [ ] **Step 1: Write the failing tests** — create `tests/test_mcp.sh`:

```bash
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"
source "$ROOT/lib/mcp.sh"

test_mcp_dryrun_prints_intended_commands() {
  local home out; home="$(mktemp -d)"
  out="$( HOME="$home" DRY_RUN=1 do_mcp 2>&1 )"
  assert_contains "$out" 'server-filesystem' 'dry-run names the filesystem MCP server'
  assert_contains "$out" 'mcp add' 'dry-run shows the claude mcp add command'
  assert_contains "$out" '.claude-code-vault' 'dry-run uses the space-free symlink path'
  rm -rf "$home"
}
test_mcp_real_skips_without_npx() {
  # No npx on a stubbed PATH -> graceful skip (return 0) + manual instructions, not a hard fail.
  local home stub out rc; home="$(mktemp -d)"; stub="$(mktemp -d)"
  # provide a 'claude' so the npx check is what triggers, but NO npx/node
  printf '#!/usr/bin/env bash\nexit 0\n' > "$stub/claude"; chmod +x "$stub/claude"
  mkdir -p "$home/Documents/Claude Code Starter"
  out="$( HOME="$home" PATH="$stub" DRY_RUN=0 do_mcp 2>&1 )"; rc=$?
  assert_eq "$rc" 0 'do_mcp returns 0 (graceful) when npx is missing'
  assert_contains "$out" 'Node' 'do_mcp explains Node is needed'
  rm -rf "$home" "$stub"
}
```

> The second test sets `PATH="$stub"` (only the stub dir) so `npx` is genuinely absent. `do_mcp` must not call any other external command before its `npx` check, or use full-path-free `have` checks that simply return false.

- [ ] **Step 2: Run to verify failure**

Run: `bash tests/run.sh`
Expected: FAIL — `do_mcp: command not found`.

- [ ] **Step 3: Implement** — create `lib/mcp.sh`:

```bash
#!/usr/bin/env bash
# do_mcp: connect the Obsidian vault to Claude Code via the official filesystem
# MCP server (read+write, no API key, no Obsidian plugin). Points the server at a
# space-free symlink to dodge spaced-path fragility. Requires common.sh first.

MCP_NAME="obsidian-vault"
MCP_LINK="${HOME}/.claude-code-vault"
MCP_VAULT="${HOME}/Documents/Claude Code Starter"

_mcp_add_cmd() {
  printf 'claude mcp add --scope user %s -- npx -y @modelcontextprotocol/server-filesystem "%s"' \
    "${MCP_NAME}" "${MCP_LINK}"
}

do_mcp() {
  step "Connect vault to Claude Code (MCP)"

  if [[ "${DRY_RUN}" == "1" ]]; then
    info "[dry-run] ln -s \"${MCP_VAULT}\" \"${MCP_LINK}\""
    info "[dry-run] $(_mcp_add_cmd)"
    return 0
  fi

  if [[ ! -d "${MCP_VAULT}" ]]; then
    warn "Vault not found at '${MCP_VAULT}' — skipping MCP (the server won't start without it)."
    return 0
  fi
  if ! have npx; then
    warn "Node/npx not found — skipping the vault↔Claude connection."
    warn "Install Node 18+ from https://nodejs.org, then run:"
    printf '   %s\n' "$(_mcp_add_cmd)"
    return 0
  fi
  if ! have claude; then
    warn "claude not on PATH — skipping MCP. After opening a new terminal, run:"
    printf '   %s\n' "$(_mcp_add_cmd)"
    return 0
  fi

  # space-free symlink (idempotent)
  if [[ ! -L "${MCP_LINK}" ]]; then
    run ln -s "${MCP_VAULT}" "${MCP_LINK}" || { warn "Could not create symlink ${MCP_LINK}"; return 0; }
  fi

  # idempotent: already registered?
  if claude mcp get "${MCP_NAME}" </dev/null >/dev/null 2>&1; then
    ok "MCP server '${MCP_NAME}' already registered"
    return 0
  fi

  info "Registering MCP server '${MCP_NAME}' (user scope)"
  if claude mcp add --scope user "${MCP_NAME}" -- \
        npx -y @modelcontextprotocol/server-filesystem "${MCP_LINK}" </dev/null; then
    ok "Vault connected to Claude Code (read+write). Try: claude mcp get ${MCP_NAME}"
  else
    warn "Automatic MCP registration failed. Run this manually:"
    printf '   %s\n' "$(_mcp_add_cmd)"
  fi
}
```

- [ ] **Step 4: Run to verify pass**

Run: `bash tests/run.sh`
Expected: PASS — all three MCP tests `ok`.

- [ ] **Step 5: Commit**

```bash
git add lib/mcp.sh tests/test_mcp.sh
git commit -m "feat(mcp): connect vault to Claude Code via filesystem MCP server"
```

---

## Task 10: verify.sh — the `--verify` doctor

**Files:**
- Create: `lib/verify.sh`
- Test: `tests/test_verify.sh` (create)

- [ ] **Step 1: Write the failing tests** — create `tests/test_verify.sh`:

```bash
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"
source "$ROOT/lib/verify.sh"

test_verify_reports_missing_as_fail() {
  # Empty HOME + empty PATH stub: nothing is installed -> non-zero + ✗ markers.
  local home stub out rc; home="$(mktemp -d)"; stub="$(mktemp -d)"
  out="$( HOME="$home" PATH="$stub" do_verify 2>&1 )"; rc=$?
  assert_ok "[[ $rc -ne 0 ]]" 'do_verify exits non-zero when critical checks fail'
  assert_contains "$out" 'claude' 'verify reports the claude check'
  rm -rf "$home" "$stub"
}
test_verify_passes_with_stubs() {
  # Stub claude (version + mcp get + plugin list) and npx; create vault + settings.
  local home stub out rc; home="$(mktemp -d)"; stub="$(mktemp -d)"
  cat > "$stub/claude" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  --version) echo "claude 9.9.9";;
  mcp) [ "$2" = "get" ] && exit 0;;
  plugin) echo "superpowers"; exit 0;;
esac
exit 0
EOF
  chmod +x "$stub/claude"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$stub/npx"; chmod +x "$stub/npx"
  mkdir -p "$home/.claude" "$home/Documents/Claude Code Starter"
  printf '{}' > "$home/.claude/settings.json"
  ln -s "$home/Documents/Claude Code Starter" "$home/.claude-code-vault"
  out="$( HOME="$home" PATH="$stub" do_verify 2>&1 )"; rc=$?
  assert_eq "$rc" 0 'do_verify exits 0 when everything is present'
  rm -rf "$home" "$stub"
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bash tests/run.sh`
Expected: FAIL — `do_verify: command not found`.

- [ ] **Step 3: Implement** — create `lib/verify.sh`:

```bash
#!/usr/bin/env bash
# do_verify: non-mutating health check. Prints ✓/✗ per check with a remediation
# hint on failure. Returns non-zero if any CRITICAL check fails (claude/vault/mcp).
# Plugin & settings gaps are warnings (don't fail the overall result).

_VFAIL=0   # critical failures
_pass() { ok "$1"; }
_warnv() { warn "$1"; }
_failv() { err "$1"; _VFAIL=$((_VFAIL+1)); }

do_verify() {
  step "Verify"
  _VFAIL=0
  local vault="${HOME}/Documents/Claude Code Starter"
  local link="${HOME}/.claude-code-vault"

  # critical: claude
  if have claude; then _pass "claude on PATH ($(claude --version 2>/dev/null | head -1))"
  else _failv "claude not on PATH — open a new terminal, or re-run setup.sh"; fi

  # critical: vault
  if [[ -d "$vault" ]]; then _pass "vault present ($vault)"
  else _failv "vault missing — re-run setup.sh (or with --skip-mcp)"; fi
  if [[ -L "$link" ]]; then _pass "vault symlink resolves ($link)"
  else _warnv "vault symlink $link missing — MCP may be unconfigured"; fi

  # node/npx (needed for MCP)
  if have npx; then _pass "npx present"; else _warnv "npx/Node missing — needed for the vault MCP server"; fi

  # critical: mcp registered
  if have claude && claude mcp get obsidian-vault </dev/null >/dev/null 2>&1; then
    _pass "MCP 'obsidian-vault' registered"
  else
    _failv "MCP 'obsidian-vault' not registered — see README, or re-run setup.sh"
  fi

  # warnings: plugins + settings
  if have claude; then
    local p list; list="$(claude plugin list </dev/null 2>/dev/null || true)"
    for p in superpowers andrej-karpathy-skills feature-dev pr-review-toolkit commit-commands hookify; do
      case "$list" in *"$p"*) _pass "plugin: $p";; *) _warnv "plugin not found: $p (re-run setup.sh)";; esac
    done
  fi
  if [[ -f "${HOME}/.claude/settings.json" ]]; then _pass "settings.json present"
  else _warnv "no ~/.claude/settings.json (optional)"; fi

  if [[ "${_VFAIL}" -gt 0 ]]; then
    err "Verify: ${_VFAIL} critical check(s) failed."
    return 1
  fi
  ok "Verify: all critical checks passed."
  return 0
}
```

- [ ] **Step 4: Run to verify pass**

Run: `bash tests/run.sh`
Expected: PASS — both verify tests `ok`.

- [ ] **Step 5: Commit**

```bash
git add lib/verify.sh tests/test_verify.sh
git commit -m "feat(verify): add do_verify health check (powers --verify)"
```

---

## Task 11: Wire new modules into setup.sh (flags, flow, trap, --verify)

**Files:**
- Modify: `setup.sh`
- Modify: `tests/test_setup_args.sh` (add skip-flag matrix + --verify)

- [ ] **Step 1: Write the failing tests** — append to `tests/test_setup_args.sh`:

```bash
test_new_skip_flags() {
  parse_args --skip-config --skip-mcp
  assert_eq "$SKIP_CONFIG" 1 '--skip-config'
  assert_eq "$SKIP_MCP" 1 '--skip-mcp'
}
test_verify_flag() {
  parse_args --verify
  assert_eq "$VERIFY_ONLY" 1 '--verify sets VERIFY_ONLY'
}
test_skip_flag_matrix() {
  local combos=("" "--skip-obsidian" "--skip-plugins" "--skip-vault" "--skip-config" "--skip-mcp" \
    "--skip-obsidian --skip-plugins --skip-vault --skip-config --skip-mcp")
  local c
  for c in "${combos[@]}"; do
    parse_args $c
    case "$c" in *obsidian*) assert_eq "$SKIP_OBSIDIAN" 1 "obsidian gated [$c]";; *) assert_eq "$SKIP_OBSIDIAN" 0 "obsidian on [$c]";; esac
    case "$c" in *config*)   assert_eq "$SKIP_CONFIG"  1 "config gated [$c]";;   *) assert_eq "$SKIP_CONFIG"  0 "config on [$c]";; esac
    case "$c" in *mcp*)      assert_eq "$SKIP_MCP"     1 "mcp gated [$c]";;      *) assert_eq "$SKIP_MCP"     0 "mcp on [$c]";; esac
  done
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bash tests/run.sh`
Expected: FAIL — `SKIP_CONFIG`/`SKIP_MCP`/`VERIFY_ONLY` unbound.

- [ ] **Step 3: Implement setup.sh changes.**

(a) In `parse_args` add defaults + cases. Update both the default-init line and the `while` loop:

```bash
  DRY_RUN=0; ASSUME_YES=0; SKIP_OBSIDIAN=0; SKIP_PLUGINS=0; SKIP_VAULT=0; SKIP_CONFIG=0; SKIP_MCP=0; VERIFY_ONLY=0
```
```bash
      --skip-config)   SKIP_CONFIG=1 ;;
      --skip-mcp)      SKIP_MCP=1 ;;
      --verify)        VERIFY_ONLY=1 ;;
```
And add them to the `export` line:
```bash
  export DRY_RUN ASSUME_YES SKIP_OBSIDIAN SKIP_PLUGINS SKIP_VAULT SKIP_CONFIG SKIP_MCP VERIFY_ONLY
```
Also extend `usage()` with the three new flags.

(b) Source the new modules — extend the module loop list:

```bash
  for m in preflight claude-code obsidian plugins vault config mcp verify; do
```

(c) Add the EXIT trap + `--verify` short-circuit at the top of `main()` (after `parse_args` and after sourcing):

```bash
  if [[ "${VERIFY_ONLY}" == "1" ]]; then do_verify; return $?; fi

  cleanup() {
    local rc=$?
    if [[ $rc -ne 0 ]]; then
      err "setup failed (exit ${rc}). Nothing was left half-installed by this run."
      err "Re-running is safe — it skips anything already installed."
    fi
  }
  trap cleanup EXIT
```

(d) Update the orchestration flow with the new steps + skips:

```bash
  do_preflight
  do_claude_code
  if [[ "${SKIP_CONFIG}"   == "1" ]]; then info "Skipping settings (--skip-config)"; else do_config; fi
  if [[ "${SKIP_OBSIDIAN}" == "1" ]]; then info "Skipping Obsidian (--skip-obsidian)"; else do_obsidian; fi
  if [[ "${SKIP_PLUGINS}"  == "1" ]]; then info "Skipping plugins (--skip-plugins)"; else do_plugins; fi
  if [[ "${SKIP_VAULT}"    == "1" ]]; then info "Skipping vault (--skip-vault)"; else do_vault; fi
  if [[ "${SKIP_MCP}"      == "1" ]]; then info "Skipping MCP (--skip-mcp)"; else do_mcp; fi
  do_verify || warn "Some post-install checks failed — run 'setup.sh --verify' for details."
```

(e) Update `final_message` to mention the unified vault path (`~/Documents/Claude Code Starter`) and `setup.sh --verify`.

- [ ] **Step 4: Run unit tests**

Run: `bash tests/run.sh`
Expected: PASS — matrix + new-flag + verify-flag assertions `ok`.

- [ ] **Step 5: Full dry-run smoke + permission-syntax verification**

Run: `bash setup.sh --dry-run --yes 2>&1 | tee /tmp/ccs.dry`
Expected: every step header prints (`Preflight … Claude Code … settings … Obsidian … plugins … vault … MCP … Verify`); the `[dry-run]` MCP line shows the `claude mcp add … server-filesystem … .claude-code-vault` command.

Then verify the `assets/claude-settings.json` permission-rule syntax against the installed `claude`:
```bash
claude --version
# Inspect current accepted syntax; if the installed version uses Bash(cmd *) rather
# than Bash(cmd:*), update assets/claude-settings.json to match and re-run tests.
claude config --help 2>&1 | head -20 || true
```
If the syntax differs, fix `assets/claude-settings.json` and re-commit (amend Task 3's asset).

- [ ] **Step 6: Commit**

```bash
git add setup.sh tests/test_setup_args.sh
git commit -m "feat(setup): wire config/mcp/verify, add --skip-config/--skip-mcp/--verify, EXIT trap"
```

---

## Task 12: CI — wire new tests + idempotent double-run matrix

**Files:**
- Modify: `.github/workflows/ci.yml`

- [ ] **Step 1: Read the current CI** — `cat .github/workflows/ci.yml` to match job style (it already runs shellcheck + the unit harness + a macOS dry-run smoke + vault-link).

- [ ] **Step 2: Ensure shellcheck covers the new files.** If shellcheck runs an explicit file list, add `lib/config.sh lib/mcp.sh lib/verify.sh`; if it globs `lib/*.sh` + `*.sh`, no change. The new `tests/test_*.sh` are auto-run by the existing unit job.

- [ ] **Step 3: Add an idempotent double-run job** (append under `jobs:`):

```yaml
  idempotent:
    name: idempotent double-run (${{ matrix.os }})
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: first dry-run
        run: bash setup.sh --dry-run --yes
      - name: second dry-run must be clean + complete
        run: |
          out="$(bash setup.sh --dry-run --yes)"
          echo "$out"
          echo "$out" | grep -q '=== Done ===' || { echo 'second run did not complete'; exit 1; }
```

> `--dry-run` makes this safe on a runner (no installs, no network mutations). It exercises `parse_args`, module sourcing, the new flow, and the MCP/verify dry-run branches on both OSes.

- [ ] **Step 4: Push the branch and confirm CI is green** (or run `act`/local equivalents if available). At minimum, locally:

```bash
bash tests/run.sh && bash tools/check-vault-links.sh && bash setup.sh --dry-run --yes >/dev/null && echo "local CI proxy OK"
```
Expected: `local CI proxy OK`.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: idempotent double-run matrix (ubuntu+macos) + cover new lib modules"
```

---

## Task 13: README updates

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update "What it does"** — add bullets: a **Using Claude Code** wiki shipped alongside the Karpathy wiki in one vault at `~/Documents/Claude Code Starter`; the vault is **connected to Claude Code** via the `obsidian-vault` MCP server (read+write, no API key); a conservative starter `~/.claude/settings.json` is installed only if you don't already have one.

- [ ] **Step 2: Update "Options"** — add `--skip-config`, `--skip-mcp`, and `--verify` (run health checks only). Document `CCS_REF=<tag>` to pin/override the installed release.

- [ ] **Step 3: Update "After it finishes"** — mention `setup.sh --verify` and `claude mcp get obsidian-vault`.

- [ ] **Step 4: Update "Uninstall"** — add: `rm -rf ~/Documents/"Claude Code Starter"`; `rm -f ~/.claude-code-vault`; `claude mcp remove obsidian-vault`; note the starter `settings.json` is only created if you had none.

- [ ] **Step 5 (optional): Publish bootstrap SHA256** — add a line users can verify: `shasum -a 256 bootstrap.sh`. Include the current hash.

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: README for v0.2 (Using-CC wiki, MCP connection, --verify, CCS_REF)"
```

---

## Task 14: Release prep (manual, gated on Casey)

**Files:** none (git operations)

- [ ] **Step 1: Final local verification**

```bash
bash tests/run.sh && bash tools/check-vault-links.sh && bash setup.sh --dry-run --yes >/dev/null && echo OK
```

- [ ] **Step 2: Open PR** (do NOT push/tag without Casey's go-ahead). When approved:

```bash
git push -u origin feat/starter-v02
gh pr create --fill --base main
```

- [ ] **Step 3: After merge to main, tag the release** (this is what makes `bootstrap.sh`'s "latest release tag" resolve):

```bash
git checkout main && git pull
git tag -a v0.2.0 -m "v0.2.0 — Using Claude Code wiki, vault↔Claude MCP, --verify, hardened bootstrap"
git push origin v0.2.0
```

- [ ] **Step 4: Smoke the real one-liner** on a clean macOS account (or `acceptance.yml` dispatch): run the `curl … | bash` command, then `setup.sh --verify`, confirm all-green and `claude mcp get obsidian-vault` connects.

---

## Self-Review

**Spec coverage:**
- §3.2 common.sh helpers → Task 1 ✓
- §3.3 bootstrap hardening (pin/atomic/partial-pipe) → Task 2 ✓
- §6 starter settings.json → Task 3 ✓
- §4 unified vault + CLAUDE.md + MOC → Task 4 ✓; §4.1 Using-CC notes → Task 5 ✓
- §9 vault-link checker recursion → Task 6 ✓
- §5 plugin additions → Task 7 ✓
- §3.2 vault.sh dest → Task 8 ✓
- §3.2 + Decisions: MCP connection (symlink, user scope, graceful Node skip) → Task 9 ✓
- §3.2 verify/doctor → Task 10 ✓
- §3.2 setup.sh integration (--verify, traps, skip flags, flow) → Task 11 ✓
- §9 CI (idempotent double-run, new tests) + network-failure sim → Task 12 (+ Task 2 covers the network-failure unit test) ✓
- §10 uninstall/README → Task 13 ✓
- §8.6 release tag (so latest-tag resolves) → Task 14 ✓
- §8.3 permission-syntax verification → Task 11 Step 5 ✓

**Placeholder scan:** No "TBD"/"implement later". Task 5 intentionally provides a template + one full worked note + an exact filename list + per-note content guidance (prose content, not code) — acceptable per the writing-plans content-vs-code distinction. Task 6/7/12 begin with a "read the current file" step because the exact line to edit depends on the current text; the change to make is given explicitly.

**Type/name consistency:** Module fns `do_config`/`do_mcp`/`do_verify`; vars `VAULT_DEST` (vault.sh) vs `MCP_VAULT`/`MCP_LINK`/`MCP_NAME` (mcp.sh) — distinct on purpose; `SKIP_CONFIG`/`SKIP_MCP`/`VERIFY_ONLY` used identically in Task 11 tests and impl; the symlink `~/.claude-code-vault` and MCP name `obsidian-vault` are consistent across Tasks 9, 10, 11, 13. Helper names `need_cmd`/`ensure`/`fatal` (Task 1) are reused in later tasks' impls.
