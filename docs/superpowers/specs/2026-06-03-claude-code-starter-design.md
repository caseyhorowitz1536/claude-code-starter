# claude-code-starter — Design Spec

**Date:** 2026-06-03
**Owner:** Casey Horowitz (`caseyhorowitz1536`)
**Status:** Approved design — ready for implementation planning

## 1. Problem & Goal

People keep asking Casey to help them set up Claude Code, and doing it by hand
(install the CLI, install Obsidian, build an LLM study vault, hand-pick useful
skills) takes a long time and is error-prone. We want a **single automation** a
newcomer can run on a fresh Mac that sets up everything at once:

1. Install **Claude Code** (the CLI) into their terminal.
2. Install **Obsidian** and drop in a ready-made **Andrej Karpathy LLM wiki** vault.
3. Install a **curated set of skills** that help new Claude Code users be productive.

**Success criteria (observable):** On a clean macOS machine, a user runs one
command; afterward `claude --version` works, `Obsidian.app` is installed, a
"Karpathy LLM Wiki" vault exists and opens with a populated graph view, and the
curated skills appear under `~/.claude/skills/` (plus the curated plugins are
registered). The only remaining manual step is `claude` → `/login` (browser auth).

## 2. Locked Decisions

From the brainstorming session (2026-06-03):

| Decision | Choice | Rationale |
|---|---|---|
| Karpathy LLM wiki source | **Generate fresh**, authored now as **static** markdown vendored in the repo | Deterministic, no API key / tokens needed at install time, inspectable |
| Target OS | **macOS only** | Matches Casey's setup; one bash script; smallest correct surface |
| Skills to bundle | **Curated starter set** (superpowers + karpathy-guidelines + a few official plugins) | New users don't need the ~20 finance/PE plugins or the gsd-* fleet |
| Delivery | **Public git repo + one-liner bootstrap** | Inspectable and versioned, plus a convenient `curl … \| bash` |
| Repo | `caseyhorowitz1536/claude-code-starter` (public), built at `~/Documents/GitHub/claude-code-starter` | One-liner URL bakes in the repo path |
| Vault install path | `~/Documents/Karpathy LLM Wiki/` as its **own** vault | Keeps it isolated from Casey's private `~/Documents/Obsidian Vault/` |
| Vault depth | **~25–35 interlinked notes** | Rich enough for a good graph; small enough to author and maintain |

### Chosen approach: **A — self-contained, vendored, idempotent**

Everything (skills, vault, scripts) ships in the repo. `setup.sh` installs tools
and copies vendored assets into place. Rejected: **B** (generate vault on the
user's machine — chicken/egg auth, non-deterministic, slow, fragile) and a full
**C** menu system (YAGNI — we keep only a couple of `--skip-*` flags from it).

## 3. Architecture

### 3.1 Repo layout

```
claude-code-starter/
├── bootstrap.sh          # one-liner entrypoint: clone repo (or pull) + exec setup.sh
├── setup.sh              # idempotent orchestrator; parses flags; sources lib/*.sh
├── lib/
│   ├── common.sh         # logging, color, confirm, backup(), have() helpers; set -euo pipefail
│   ├── preflight.sh      # assert macOS; ensure Xcode CLT; ensure Homebrew
│   ├── claude-code.sh    # official install.sh; ensure ~/.local/bin on PATH; verify
│   ├── obsidian.sh       # brew install --cask obsidian (skip if present)
│   ├── skills.sh         # copy skills/* → ~/.claude/skills/ (backup existing)
│   ├── plugins.sh        # claude plugin marketplace add + install curated set
│   └── vault.sh          # copy vault/ → ~/Documents/Karpathy LLM Wiki/ (no clobber)
├── skills/               # vendored curated skills (see §5)
├── vault/                # the pre-authored Karpathy LLM Wiki + .obsidian/ (see §4)
├── README.md             # what it does, the one-liner, manual steps, uninstall
└── docs/superpowers/…    # this spec + the implementation plan
```

### 3.2 Component contracts

Each `lib/*.sh` exposes one `do_<area>` function, is independently runnable, and
is **idempotent** (safe to re-run) and **non-destructive** (backs up before
overwrite). Contracts:

- **common.sh** — `log/info/warn/err`, `have <cmd>` (command exists?), `backup
  <path>` (moves to `<path>.bak.<n>`), `confirm <msg>` (honors
  `--yes`/non-interactive). No side effects on source.
- **preflight.sh** `do_preflight` — exits non-zero with a clear message if not
  macOS; triggers `xcode-select --install` if CLT missing; installs Homebrew via
  the official script if `brew` absent. Depends on: network, `common.sh`.
- **claude-code.sh** `do_claude_code` — runs the official Claude Code `install.sh`
  if `claude` not found; ensures the install dir (`~/.local/bin`) is on `PATH` in
  the user's shell rc; verifies with `claude --version`. Depends on: network.
- **obsidian.sh** `do_obsidian` — `brew install --cask obsidian` unless
  `/Applications/Obsidian.app` exists. Depends on: Homebrew.
- **skills.sh** `do_skills` — for each folder in `skills/`, back up any existing
  `~/.claude/skills/<name>` then copy. Idempotent. Depends on: nothing external.
- **plugins.sh** `do_plugins` — **primary (hard-require) path:** register the
  marketplace with `claude plugin marketplace add anthropics/claude-plugins-official`
  then `claude plugin install <name>@claude-plugins-official --scope user` for each
  curated plugin. Each call runs with stdin from `/dev/null` and wrapped in
  `timeout` so a fresh-machine trust prompt cannot hang `curl | bash`. **Fallback:**
  if any command exits non-zero (or times out), log it and print a manual
  `/plugin install …` checklist instead. Depends on: `claude` on PATH.
- **vault.sh** `do_vault` — copy `vault/` to `~/Documents/Karpathy LLM Wiki/`
  only if the target doesn't already exist (never clobber a user's vault);
  optionally `open -a Obsidian` the vault at the end. Depends on: nothing.

### 3.3 Orchestration & flow (`setup.sh`)

```
do_preflight → do_claude_code → do_obsidian → do_skills → do_plugins → do_vault → final_message
```

- **Flags:** `--skip-obsidian`, `--skip-plugins`, `--skip-vault`, `--yes`
  (non-interactive), `--help`. Unknown flags error out.
- **final_message:** prints the one remaining manual step — start `claude`, run
  `/login` — plus where the vault landed and how to open it.
- **Failure handling:** `set -euo pipefail`; each step prints what it's doing;
  on failure, the script reports which step failed and that re-running is safe
  (idempotency). No silent failures — every skipped step is logged with the
  reason (e.g. "Obsidian already installed — skipping").

### 3.4 bootstrap.sh (the one-liner)

`curl -fsSL https://raw.githubusercontent.com/caseyhorowitz1536/claude-code-starter/main/bootstrap.sh | bash`

Clones the repo to `~/.claude-code-starter` (or `git pull` if present), then
`exec`s `setup.sh "$@"`. Keeps the heavy logic in the inspectable repo, not in
the piped script.

## 4. The Karpathy LLM Wiki vault

Static markdown authored at build time (by an agent fan-out — see the plan),
committed under `vault/`. Conventions:

- Every note: YAML frontmatter (`title`, `tags`, `source`), a short summary, the
  core idea, and **`[[wikilinks]]`** to related notes so the graph view is dense.
- Tags group clusters: `#zero-to-hero`, `#llm-overview`, `#concept`, `#moc`.
- `00 — Start Here.md` MOC links out to the major clusters.

**Planned table of contents (~25–35 notes):**

- *Zero-to-Hero:* micrograd & backprop · neuron/MLP/loss · gradient descent ·
  makemore (bigram) · makemore (MLP / Bengio 2003) · batchnorm & init ·
  activations/gradients · "Let's build GPT" (self-attention) · BPE tokenizer ·
  reproduce GPT-2
- *LLM big-picture* (Intro to LLMs + Deep Dive into LLMs): what is an LLM /
  "two files" · pretraining · base vs instruct · SFT · RLHF & RL ·
  hallucinations & model psychology · scaling laws · tool use & agents ·
  inference, sampling & context window · the "LLM OS" analogy
- *Concept atoms:* attention · softmax · cross-entropy · embeddings ·
  residual stream · layernorm · positional encoding · temperature/top-k
- *MOCs:* Start Here · Zero-to-Hero index · LLM index

**`.obsidian/` config (vendored):** graph view enabled, core plugins on
(backlinks, outline, tags), a sensible default theme, a starter workspace.
**No** community plugins (they require network fetch and break determinism).

## 5. Curated skills & plugins

**Vendored skills** (copied into `~/.claude/skills/`): the superpowers workflow
set — `brainstorming`, `writing-plans`, `executing-plans`,
`test-driven-development`, `systematic-debugging`, `requesting-code-review`,
`receiving-code-review`, `using-git-worktrees`, `verification-before-completion`,
`using-superpowers` — plus `karpathy-guidelines`.

**Curated plugins** (registered + installed via CLI): `claude-code-setup`,
`feature-dev`, `pr-review-toolkit`, `commit-commands`, `hookify` from the
official `anthropics/claude-plugins-official` marketplace.

**Deliberately excluded:** the ~20 `claude-for-financial-services` plugins, the
`gsd-*` fleet, and other niche tools — easy for a user to add later, too much for
a first run.

> **Source-of-truth note:** vendored skills are copied from Casey's machine at
> build time. License/provenance for each bundled skill must be checked before
> the repo is made public (see §7).

## 6. Non-goals (explicit)

- Does **not** authenticate the user (browser `/login` is theirs to run).
- Does **not** support Windows or Linux.
- Does **not** touch Casey's private `~/Documents/Obsidian Vault/`.
- Does **not** install community Obsidian plugins or anything requiring runtime
  network fetch beyond the documented installers.
- Does **not** generate vault content on the user's machine.

## 7. Risks & research items

1. **`claude plugin` headless install** — ✅ **RESOLVED (2026-06-03, claude
   2.1.162).** `claude plugin marketplace add <github-repo>` and `claude plugin
   install <plugin>@<marketplace> --scope user` both exist and take non-interactive
   flags. Hard-require path is primary; runtime fallback (timeout/non-zero →
   `/plugin` checklist) kept as defense against a fresh-machine trust prompt.
2. **Official Claude Code installer URL/flags** — pin the current canonical
   `install.sh` invocation for macOS.
3. **Skill licensing/provenance** — verify each vendored skill is OK to
   redistribute publicly before flipping the repo public.
4. **Homebrew on Apple Silicon vs Intel** — PATH differs
   (`/opt/homebrew` vs `/usr/local`); preflight must handle both.
5. **PATH persistence** — appending `~/.local/bin` to the right shell rc
   (zsh default on macOS) without duplicating entries.

## 8. Testing strategy

- **Lint:** `shellcheck` all scripts in CI (GitHub Actions).
- **Idempotency:** run `setup.sh` twice in a clean environment; second run must
  make no destructive changes and report skips.
- **Dry sandbox:** a `--skip-*` matrix smoke test (e.g. CI runs
  `setup.sh --skip-obsidian --skip-plugins --skip-vault --yes` to exercise
  preflight + claude-code paths without GUI installs).
- **Vault sanity:** a script asserts every `[[wikilink]]` resolves to an existing
  note (no dangling links) and that required MOCs exist.
- **Manual acceptance:** one full run on a clean macOS user account.

## 9. Uninstall / reversibility

README documents how to undo: remove `~/Documents/Karpathy LLM Wiki/`, remove the
copied `~/.claude/skills/<name>` folders (backups are kept as `*.bak.<n>`),
`brew uninstall --cask obsidian`, and the Claude Code uninstall path. The script
never deletes user data; it only adds or backs-up-then-replaces.
