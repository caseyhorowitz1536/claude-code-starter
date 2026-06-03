# claude-code-starter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A one-command macOS onboarding tool that installs Claude Code, installs Obsidian with a ready-made Andrej Karpathy LLM wiki vault, and installs a curated set of starter skills/plugins via their public marketplaces.

**Architecture:** A small public git repo with an idempotent `setup.sh` orchestrator that sources focused `lib/*.sh` step modules (each exposing one `do_<area>` function), a `bootstrap.sh` one-liner that clones-and-runs, a pre-authored Obsidian vault under `vault/`, and CI (shellcheck + dry-run + vault link check). All mutations route through a `run` helper so `--dry-run` is uniform and CI-testable. Nothing third-party is vendored — skills/plugins install from upstream marketplaces.

**Tech Stack:** Bash (POSIX-ish, `set -euo pipefail`), Homebrew, the official Claude Code `install.sh`, the `claude plugin` CLI, Obsidian, GitHub Actions, shellcheck.

**Spec:** `docs/superpowers/specs/2026-06-03-claude-code-starter-design.md`

**Repo root for all paths below:** `~/Documents/GitHub/claude-code-starter` (already `git init`-ed, branch `main`).

---

## File Structure

| File | Responsibility |
|---|---|
| `lib/common.sh` | Logging, `have`, `backup`, `confirm`, `run` (dry-run gate). No side effects on source. |
| `lib/preflight.sh` | `do_preflight`: assert macOS, detect brew prefix, ensure Xcode CLT + Homebrew. |
| `lib/claude-code.sh` | `do_claude_code`: official installer + PATH persistence + verify. |
| `lib/obsidian.sh` | `do_obsidian`: `brew install --cask obsidian` (skip if present). |
| `lib/plugins.sh` | `do_plugins`: add 3 marketplaces + install curated plugins; fallback to checklist. |
| `lib/vault.sh` | `do_vault`: copy `vault/` → `~/Documents/Karpathy LLM Wiki/` (no clobber), open. |
| `setup.sh` | Orchestrator: parse flags, source libs, dispatch in order, final message. |
| `bootstrap.sh` | One-liner: clone/pull repo, `exec setup.sh "$@"`. |
| `vault/` | Pre-authored Karpathy LLM Wiki + `.obsidian/` config. |
| `tools/check-vault-links.sh` | Asserts no dangling `[[wikilinks]]`, required MOCs exist. |
| `tests/run.sh` | Plain-bash unit tests for `common.sh` + `setup.sh` arg parsing. |
| `.github/workflows/ci.yml` | lint (shellcheck) · unit · dry-run (macOS) · vault-link jobs. |
| `README.md` | What it does, the one-liner, manual steps, uninstall. |
| `.gitignore`, `LICENSE` | Hygiene + license for Casey's original content. |

---

## Task 1: Repo skeleton, .gitignore, test harness

**Files:**
- Create: `.gitignore`
- Create: `tests/run.sh`
- Create: `lib/.gitkeep` (placeholder so the dir exists before later tasks)

- [ ] **Step 1: Create `.gitignore`**

```gitignore
.DS_Store
*.bak.*
/tmp/
```

- [ ] **Step 2: Create the test harness `tests/run.sh`**

```bash
#!/usr/bin/env bash
# Plain-bash test runner (no bats dependency). Each test_* function asserts with
# assert_eq / assert_contains / assert_ok. Exits non-zero if any assertion fails.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILS=0

assert_eq()       { if [[ "$1" != "$2" ]]; then printf 'FAIL %s: expected [%s] got [%s]\n' "$3" "$2" "$1"; FAILS=$((FAILS+1)); else printf 'ok   %s\n' "$3"; fi; }
assert_contains() { if [[ "$1" != *"$2"* ]]; then printf 'FAIL %s: [%s] missing [%s]\n' "$3" "$1" "$2"; FAILS=$((FAILS+1)); else printf 'ok   %s\n' "$3"; fi; }
assert_ok()       { if ! eval "$1"; then printf 'FAIL %s: cmd failed [%s]\n' "$2" "$1"; FAILS=$((FAILS+1)); else printf 'ok   %s\n' "$2"; fi; }

# Test files register themselves by defining test_* functions, then we run them.
# shellcheck source=/dev/null
for f in "$ROOT"/tests/test_*.sh; do [[ -e "$f" ]] && source "$f"; done
for t in $(declare -F | awk '{print $3}' | grep '^test_'); do "$t"; done

if [[ "$FAILS" -gt 0 ]]; then printf '\n%d assertion(s) failed\n' "$FAILS"; exit 1; fi
printf '\nAll tests passed\n'
```

- [ ] **Step 3: Make the harness executable and create the lib placeholder**

```bash
cd ~/Documents/GitHub/claude-code-starter
chmod +x tests/run.sh
mkdir -p lib tests tools
touch lib/.gitkeep
```

- [ ] **Step 4: Verify the harness runs with no tests yet**

Run: `cd ~/Documents/GitHub/claude-code-starter && bash tests/run.sh`
Expected: prints `All tests passed` and exits 0 (no `test_*.sh` files yet).

- [ ] **Step 5: Commit**

```bash
cd ~/Documents/GitHub/claude-code-starter
git add .gitignore tests/run.sh lib/.gitkeep
git commit -m "chore: repo skeleton + plain-bash test harness"
```

---

## Task 2: `lib/common.sh` — shared helpers (TDD)

**Files:**
- Create: `lib/common.sh`
- Test: `tests/test_common.sh`

- [ ] **Step 1: Write the failing test `tests/test_common.sh`**

```bash
#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"

test_have_true()  { assert_ok 'have bash' 'have finds bash'; }
test_have_false() { if have definitely_not_a_real_cmd_xyz; then assert_eq 1 0 'have rejects missing'; else assert_eq 0 0 'have rejects missing'; fi; }

test_run_dryrun_echoes() {
  DRY_RUN=1
  local out; out="$(run mkdir /tmp/should_not_exist_xyz 2>&1)"
  assert_contains "$out" '[dry-run] mkdir /tmp/should_not_exist_xyz' 'run echoes in dry-run'
  assert_ok '[[ ! -e /tmp/should_not_exist_xyz ]]' 'run did not execute in dry-run'
  DRY_RUN=0
}

test_backup_renames() {
  local d; d="$(mktemp -d)"; echo hi > "$d/f"
  DRY_RUN=0
  backup "$d/f"
  assert_ok "[[ -e '$d/f.bak.1' && ! -e '$d/f' ]]" 'backup moves to .bak.1'
  rm -rf "$d"
}

test_backup_noop_when_absent() {
  local d; d="$(mktemp -d)"
  assert_ok "backup '$d/missing'" 'backup is a no-op when target absent'
  rm -rf "$d"
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd ~/Documents/GitHub/claude-code-starter && bash tests/run.sh`
Expected: FAIL — `lib/common.sh` does not exist yet (source error / unbound functions).

- [ ] **Step 3: Implement `lib/common.sh`**

```bash
#!/usr/bin/env bash
# Shared helpers. Safe to source repeatedly. No side effects at source time.
# Globals (set by setup.sh): DRY_RUN (0/1), ASSUME_YES (0/1).
: "${DRY_RUN:=0}"
: "${ASSUME_YES:=0}"

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_BOLD=$'\033[1m'
else
  C_RESET=''; C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_BOLD=''
fi

info() { printf '%s\n' "${C_BLUE}•${C_RESET} $*"; }
ok()   { printf '%s\n' "${C_GREEN}✓${C_RESET} $*"; }
warn() { printf '%s\n' "${C_YELLOW}!${C_RESET} $*" >&2; }
err()  { printf '%s\n' "${C_RED}✗ $*${C_RESET}" >&2; }
step() { printf '\n%s\n' "${C_BOLD}=== $* ===${C_RESET}"; }

# have CMD -> 0 if CMD is on PATH
have() { command -v "$1" >/dev/null 2>&1; }

# run CMD ARGS... -> echo in dry-run, else execute. For mutating commands only.
run() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

# backup PATH -> if PATH exists, move it to PATH.bak.N (next free N)
backup() {
  local path="$1"
  [[ -e "$path" ]] || return 0
  local n=1
  while [[ -e "${path}.bak.${n}" ]]; do n=$((n+1)); done
  run mv "$path" "${path}.bak.${n}"
  ok "backed up ${path} -> ${path}.bak.${n}"
}

# confirm MSG -> 0 if user says yes (auto-yes when ASSUME_YES=1 or non-tty)
confirm() {
  if [[ "${ASSUME_YES}" == "1" || ! -t 0 ]]; then return 0; fi
  local reply
  printf '%s [y/N] ' "$1"
  read -r reply
  [[ "$reply" == [yY]* ]]
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ~/Documents/GitHub/claude-code-starter && bash tests/run.sh`
Expected: all `test_*` from `tests/test_common.sh` print `ok`, harness prints `All tests passed`.

- [ ] **Step 5: Commit**

```bash
git add lib/common.sh tests/test_common.sh
git commit -m "feat: common.sh helpers (run/backup/have/confirm) with tests"
```

---

## Task 3: `lib/preflight.sh` — OS, Homebrew, Xcode CLT

**Files:**
- Create: `lib/preflight.sh`

- [ ] **Step 1: Implement `lib/preflight.sh`**

```bash
#!/usr/bin/env bash
# do_preflight: assert macOS, ensure Xcode CLT + Homebrew, export BREW_PREFIX.
# Requires common.sh sourced first.

do_preflight() {
  step "Preflight"

  if [[ "$(uname -s)" != "Darwin" ]]; then
    err "This installer supports macOS only (detected $(uname -s)). Aborting."
    return 1
  fi
  ok "macOS detected ($(sw_vers -productVersion 2>/dev/null || echo '?'))"

  # Xcode Command Line Tools (provides git, cc, make — Homebrew needs them)
  if ! xcode-select -p >/dev/null 2>&1; then
    info "Installing Xcode Command Line Tools (a GUI prompt may appear)"
    run xcode-select --install || true
    warn "If a dialog opened, finish it, then re-run this script."
  else
    ok "Xcode Command Line Tools present"
  fi

  # Homebrew
  if ! have brew; then
    info "Installing Homebrew"
    if [[ "${DRY_RUN}" == "1" ]]; then
      printf '[dry-run] /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"\n'
    else
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
  else
    ok "Homebrew present"
  fi

  # Resolve brew prefix for Apple Silicon (/opt/homebrew) vs Intel (/usr/local)
  if have brew; then
    BREW_PREFIX="$(brew --prefix)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    BREW_PREFIX=/opt/homebrew
  else
    BREW_PREFIX=/usr/local
  fi
  export BREW_PREFIX
  # Make brew available in this process if freshly installed
  [[ -x "${BREW_PREFIX}/bin/brew" ]] && eval "$("${BREW_PREFIX}/bin/brew" shellenv)" || true
  ok "Homebrew prefix: ${BREW_PREFIX}"
}
```

- [ ] **Step 2: Dry-run smoke check (macOS only)**

Run: `cd ~/Documents/GitHub/claude-code-starter && DRY_RUN=1 bash -c 'source lib/common.sh; source lib/preflight.sh; do_preflight'`
Expected (on macOS with brew present): prints `macOS detected`, `Homebrew present`, `Homebrew prefix: /opt/homebrew`, exit 0.

- [ ] **Step 3: Commit**

```bash
git add lib/preflight.sh
git commit -m "feat: preflight (macOS gate, Xcode CLT, Homebrew, brew prefix)"
```

---

## Task 4: `lib/claude-code.sh` — install Claude Code + PATH

**Files:**
- Create: `lib/claude-code.sh`

- [ ] **Step 1: Verify the official installer URL is reachable**

Run: `curl -fsSL -o /dev/null -w '%{http_code}\n' https://claude.ai/install.sh`
Expected: `200`. (If not 200, pin the current canonical macOS install command from the Claude Code docs before continuing — this is the one external URL the script depends on.)

- [ ] **Step 2: Implement `lib/claude-code.sh`**

```bash
#!/usr/bin/env bash
# do_claude_code: install Claude Code (native installer) and ensure it's on PATH.
# Requires common.sh sourced first.

_ensure_local_bin_on_path() {
  local bindir="${HOME}/.local/bin" rc="${HOME}/.zshrc"
  local line="export PATH=\"\$HOME/.local/bin:\$PATH\""
  case ":${PATH}:" in *":${bindir}:"*) ;; *) export PATH="${bindir}:${PATH}";; esac
  if [[ -f "$rc" ]] && grep -qF '.local/bin' "$rc"; then
    ok "~/.local/bin already in ${rc}"
    return 0
  fi
  info "Adding ~/.local/bin to PATH in ${rc}"
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '[dry-run] printf "\\n%%s\\n" %q >> %s\n' "$line" "$rc"
  else
    printf '\n%s\n' "$line" >> "$rc"
  fi
}

do_claude_code() {
  step "Claude Code"
  if have claude; then
    ok "Claude Code already installed ($(claude --version 2>/dev/null | head -1))"
  else
    info "Installing Claude Code via the official installer"
    if [[ "${DRY_RUN}" == "1" ]]; then
      printf '[dry-run] curl -fsSL https://claude.ai/install.sh | bash\n'
    else
      curl -fsSL https://claude.ai/install.sh | bash
    fi
  fi
  _ensure_local_bin_on_path
  if [[ "${DRY_RUN}" != "1" ]]; then
    if have claude; then ok "claude on PATH: $(command -v claude)"; else warn "claude not on PATH yet — open a new terminal after setup"; fi
  fi
}
```

- [ ] **Step 3: Dry-run smoke check**

Run: `cd ~/Documents/GitHub/claude-code-starter && DRY_RUN=1 bash -c 'source lib/common.sh; source lib/claude-code.sh; do_claude_code'`
Expected: if `claude` present, prints "already installed"; else prints the `[dry-run] curl … | bash` line. Then a PATH line. Exit 0.

- [ ] **Step 4: Commit**

```bash
git add lib/claude-code.sh
git commit -m "feat: install Claude Code via official installer + PATH persistence"
```

---

## Task 5: `lib/obsidian.sh` — install Obsidian

**Files:**
- Create: `lib/obsidian.sh`

- [ ] **Step 1: Implement `lib/obsidian.sh`**

```bash
#!/usr/bin/env bash
# do_obsidian: install Obsidian via Homebrew cask unless already present.
# Requires common.sh + preflight (brew) first.

do_obsidian() {
  step "Obsidian"
  if [[ -d "/Applications/Obsidian.app" ]]; then
    ok "Obsidian already installed — skipping"
    return 0
  fi
  if ! have brew; then
    warn "Homebrew not available — cannot install Obsidian. Install it from https://obsidian.md and re-run with --skip-obsidian."
    return 0
  fi
  info "Installing Obsidian (brew cask)"
  run brew install --cask obsidian
}
```

- [ ] **Step 2: Dry-run smoke check**

Run: `cd ~/Documents/GitHub/claude-code-starter && DRY_RUN=1 bash -c 'source lib/common.sh; source lib/obsidian.sh; do_obsidian'`
Expected: if `/Applications/Obsidian.app` exists, "already installed"; else `[dry-run] brew install --cask obsidian`. Exit 0.

- [ ] **Step 3: Commit**

```bash
git add lib/obsidian.sh
git commit -m "feat: install Obsidian via Homebrew cask (idempotent)"
```

---

## Task 6: `lib/plugins.sh` — marketplaces + curated plugins (hard-require CLI, fallback to checklist)

**Files:**
- Create: `lib/plugins.sh`

- [ ] **Step 1: Confirm marketplace names from each repo's manifest**

Run:
```bash
for repo in anthropics/claude-plugins-official obra/superpowers-marketplace forrestchang/andrej-karpathy-skills; do
  echo "== $repo =="; curl -fsSL "https://raw.githubusercontent.com/$repo/HEAD/.claude-plugin/marketplace.json" 2>/dev/null | grep -m1 '"name"' || echo '(no top-level name found — verify path)'
done
```
Expected: a `"name": "…"` for each. Use those names as the `@<marketplace>` half below. The values assumed here are `claude-plugins-official`, `superpowers-marketplace`, `karpathy-skills`. If a manifest differs, update the `MARKETPLACES`/`PLUGINS` arrays in Step 2 to match.

- [ ] **Step 2: Implement `lib/plugins.sh`**

```bash
#!/usr/bin/env bash
# do_plugins: register curated marketplaces and install curated plugins headlessly.
# Hard-require path: claude plugin marketplace add + install. On any failure,
# fall back to printing a manual /plugin checklist. Requires common.sh first.

# "repo|marketplace-name"
MARKETPLACES=(
  "anthropics/claude-plugins-official|claude-plugins-official"
  "obra/superpowers-marketplace|superpowers-marketplace"
  "forrestchang/andrej-karpathy-skills|karpathy-skills"
)
# "plugin@marketplace-name"
PLUGINS=(
  "superpowers@superpowers-marketplace"
  "andrej-karpathy-skills@karpathy-skills"
  "claude-code-setup@claude-plugins-official"
  "feature-dev@claude-plugins-official"
  "pr-review-toolkit@claude-plugins-official"
  "commit-commands@claude-plugins-official"
  "hookify@claude-plugins-official"
)

# Run a claude subcommand non-interactively: no stdin (so a trust prompt can't
# hang), bounded by timeout. Returns the command's exit code.
_claude() {
  local t="timeout"; have timeout || t="" # gtimeout/none on some macs; degrade gracefully
  if [[ "${DRY_RUN}" == "1" ]]; then printf '[dry-run] claude %s\n' "$*"; return 0; fi
  if [[ -n "$t" ]]; then ${t} 120 claude "$@" </dev/null; else claude "$@" </dev/null; fi
}

_print_manual_checklist() {
  warn "Falling back to a manual checklist. In a Claude Code session, run:"
  local m p
  for m in "${MARKETPLACES[@]}"; do printf '   /plugin marketplace add %s\n' "${m%%|*}"; done
  for p in "${PLUGINS[@]}"; do printf '   /plugin install %s\n' "$p"; done
}

do_plugins() {
  step "Skills & plugins"
  if [[ "${DRY_RUN}" != "1" ]] && ! have claude; then
    warn "claude not on PATH — skipping automated plugin install."
    _print_manual_checklist
    return 0
  fi

  local failed=0 entry repo
  for entry in "${MARKETPLACES[@]}"; do
    repo="${entry%%|*}"
    info "Registering marketplace ${repo}"
    _claude plugin marketplace add "${repo}" || { warn "marketplace add failed: ${repo}"; failed=1; }
  done

  local p
  for p in "${PLUGINS[@]}"; do
    info "Installing ${p}"
    _claude plugin install "${p}" --scope user || { warn "install failed: ${p}"; failed=1; }
  done

  if [[ "${failed}" -eq 1 ]]; then
    _print_manual_checklist
  else
    ok "Curated skills & plugins installed"
  fi
}
```

- [ ] **Step 3: Dry-run smoke check**

Run: `cd ~/Documents/GitHub/claude-code-starter && DRY_RUN=1 bash -c 'source lib/common.sh; source lib/plugins.sh; do_plugins'`
Expected: `[dry-run] claude plugin marketplace add …` ×3 then `[dry-run] claude plugin install …` ×7, then "installed". Exit 0.

- [ ] **Step 4: Commit**

```bash
git add lib/plugins.sh
git commit -m "feat: install curated skills/plugins via marketplaces (CLI + fallback)"
```

---

## Task 7: `lib/vault.sh` — copy the Karpathy vault (no clobber)

**Files:**
- Create: `lib/vault.sh`

- [ ] **Step 1: Implement `lib/vault.sh`**

```bash
#!/usr/bin/env bash
# do_vault: copy the bundled vault to ~/Documents/Karpathy LLM Wiki/ (never clobber).
# Requires common.sh first. Expects $REPO_DIR to point at the repo root.

VAULT_DEST="${HOME}/Documents/Karpathy LLM Wiki"

do_vault() {
  step "Karpathy LLM Wiki vault"
  local src="${REPO_DIR}/vault"
  if [[ ! -d "$src" ]]; then err "bundled vault missing at ${src}"; return 1; fi

  if [[ -d "$VAULT_DEST" ]]; then
    ok "Vault already exists at '${VAULT_DEST}' — leaving it untouched"
  else
    info "Installing vault to '${VAULT_DEST}'"
    run mkdir -p "${HOME}/Documents"
    run cp -R "$src" "$VAULT_DEST"
    ok "Vault installed"
  fi

  if [[ "${DRY_RUN}" != "1" ]] && [[ -d "/Applications/Obsidian.app" ]] && confirm "Open the vault in Obsidian now?"; then
    run open -a Obsidian "$VAULT_DEST"
  fi
}
```

- [ ] **Step 2: Dry-run smoke check**

Run: `cd ~/Documents/GitHub/claude-code-starter && DRY_RUN=1 REPO_DIR="$PWD" bash -c 'source lib/common.sh; source lib/vault.sh; mkdir -p vault; do_vault'`
Expected: if dest exists, "already exists"; else `[dry-run] cp -R …/vault …/Karpathy LLM Wiki`. Exit 0.

- [ ] **Step 3: Commit**

```bash
git add lib/vault.sh
git commit -m "feat: install Karpathy vault to ~/Documents (no-clobber)"
```

---

## Task 8: `setup.sh` — orchestrator + flags (TDD on arg parsing)

**Files:**
- Create: `setup.sh`
- Test: `tests/test_setup_args.sh`

- [ ] **Step 1: Write the failing test `tests/test_setup_args.sh`**

```bash
#!/usr/bin/env bash
# setup.sh must be source-safe: define parse_args + globals without running main.
# shellcheck source=/dev/null
REPO_DIR="$ROOT" source "$ROOT/setup.sh"

test_defaults() {
  parse_args
  assert_eq "$DRY_RUN" 0 'DRY_RUN defaults 0'
  assert_eq "$SKIP_OBSIDIAN" 0 'SKIP_OBSIDIAN defaults 0'
}
test_flags() {
  parse_args --dry-run --skip-obsidian --skip-plugins --skip-vault --yes
  assert_eq "$DRY_RUN" 1 '--dry-run sets DRY_RUN'
  assert_eq "$SKIP_OBSIDIAN" 1 '--skip-obsidian'
  assert_eq "$SKIP_PLUGINS" 1 '--skip-plugins'
  assert_eq "$SKIP_VAULT" 1 '--skip-vault'
  assert_eq "$ASSUME_YES" 1 '--yes'
}
test_unknown_flag_fails() {
  if ( parse_args --bogus ) >/dev/null 2>&1; then assert_eq 1 0 'unknown flag should fail'; else assert_eq 0 0 'unknown flag fails'; fi
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd ~/Documents/GitHub/claude-code-starter && bash tests/run.sh`
Expected: FAIL — `setup.sh` does not exist.

- [ ] **Step 3: Implement `setup.sh`**

```bash
#!/usr/bin/env bash
# claude-code-starter — one-shot macOS onboarding orchestrator.
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export REPO_DIR

# Defaults (overridable by flags)
DRY_RUN=0; ASSUME_YES=0
SKIP_OBSIDIAN=0; SKIP_PLUGINS=0; SKIP_VAULT=0

usage() {
  cat <<'EOF'
Usage: setup.sh [options]
  --skip-obsidian   Don't install Obsidian
  --skip-plugins    Don't install skills/plugins
  --skip-vault      Don't install the Karpathy vault
  --yes             Non-interactive (assume yes to prompts)
  --dry-run         Log intended actions without changing anything
  --help            Show this help
EOF
}

parse_args() {
  DRY_RUN=0; ASSUME_YES=0; SKIP_OBSIDIAN=0; SKIP_PLUGINS=0; SKIP_VAULT=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-obsidian) SKIP_OBSIDIAN=1 ;;
      --skip-plugins)  SKIP_PLUGINS=1 ;;
      --skip-vault)    SKIP_VAULT=1 ;;
      --yes|-y)        ASSUME_YES=1 ;;
      --dry-run)       DRY_RUN=1 ;;
      --help|-h)       usage; return 0 ;;
      *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; return 2 ;;
    esac
    shift
  done
  export DRY_RUN ASSUME_YES SKIP_OBSIDIAN SKIP_PLUGINS SKIP_VAULT
}

main() {
  parse_args "$@"
  # shellcheck source=/dev/null
  source "${REPO_DIR}/lib/common.sh"
  for m in preflight claude-code obsidian plugins vault; do
    # shellcheck source=/dev/null
    source "${REPO_DIR}/lib/${m}.sh"
  done

  printf '%s\n' "${C_BOLD}Claude Code Starter${C_RESET} — setting up your terminal"
  [[ "${DRY_RUN}" == "1" ]] && warn "DRY RUN — no changes will be made"

  do_preflight
  do_claude_code
  [[ "${SKIP_OBSIDIAN}" == "1" ]] && info "Skipping Obsidian (--skip-obsidian)" || do_obsidian
  [[ "${SKIP_PLUGINS}"  == "1" ]] && info "Skipping plugins (--skip-plugins)"  || do_plugins
  [[ "${SKIP_VAULT}"    == "1" ]] && info "Skipping vault (--skip-vault)"      || do_vault

  final_message
}

final_message() {
  step "Done"
  cat <<EOF
${C_GREEN}Setup complete.${C_RESET}

Last step (one-time, requires a browser):
  1. Open a NEW terminal window (so PATH updates apply)
  2. Run:  claude
  3. In Claude Code, log in with:  /login

Your Karpathy LLM Wiki is at:
  ~/Documents/Karpathy LLM Wiki    (open it in Obsidian)

Re-running this script is safe — it skips anything already installed.
EOF
}

# Only run main when executed, not when sourced (so tests can call parse_args).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ~/Documents/GitHub/claude-code-starter && bash tests/run.sh`
Expected: all `test_setup_args` + `test_common` assertions `ok`; `All tests passed`.

- [ ] **Step 5: Full dry-run of the orchestrator (macOS)**

Run: `cd ~/Documents/GitHub/claude-code-starter && mkdir -p vault && bash setup.sh --dry-run --yes`
Expected: prints the banner + `DRY RUN` warning, each `=== … ===` step header in order (Preflight → Claude Code → Obsidian → Skills & plugins → Karpathy LLM Wiki vault → Done), `[dry-run]` lines for mutations, exits 0. No files created outside the repo.

- [ ] **Step 6: Commit**

```bash
git add setup.sh tests/test_setup_args.sh
git commit -m "feat: setup.sh orchestrator with flags, dry-run, and arg tests"
```

---

## Task 9: `bootstrap.sh` — the one-liner

**Files:**
- Create: `bootstrap.sh`

- [ ] **Step 1: Implement `bootstrap.sh`**

```bash
#!/usr/bin/env bash
# One-liner entrypoint:
#   curl -fsSL https://raw.githubusercontent.com/caseyhorowitz1536/claude-code-starter/main/bootstrap.sh | bash
# Clones (or updates) the repo locally, then runs setup.sh. All heavy logic lives
# in the inspectable repo, not in this piped script.
set -euo pipefail

REPO_URL="https://github.com/caseyhorowitz1536/claude-code-starter.git"
DEST="${HOME}/.claude-code-starter"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required (install Xcode Command Line Tools: xcode-select --install)" >&2
  exit 1
fi

if [[ -d "${DEST}/.git" ]]; then
  echo "• Updating ${DEST}"
  git -C "${DEST}" pull --ff-only
else
  echo "• Cloning into ${DEST}"
  git clone --depth 1 "${REPO_URL}" "${DEST}"
fi

exec bash "${DEST}/setup.sh" "$@"
```

- [ ] **Step 2: Lint it**

Run: `cd ~/Documents/GitHub/claude-code-starter && bash -n bootstrap.sh && echo 'syntax ok'`
Expected: `syntax ok`. (Full clone path is exercised in manual acceptance — Task 14 — since it needs the public repo to exist.)

- [ ] **Step 3: Commit**

```bash
git add bootstrap.sh
git commit -m "feat: bootstrap.sh one-liner (clone/pull + exec setup.sh)"
```

---

## Task 10: Vault `.obsidian/` config

**Files:**
- Create: `vault/.obsidian/app.json`
- Create: `vault/.obsidian/core-plugins.json`
- Create: `vault/.obsidian/graph.json`
- Create: `vault/.obsidian/appearance.json`

- [ ] **Step 1: Create `vault/.obsidian/app.json`**

```json
{
  "alwaysUpdateLinks": true,
  "newLinkFormat": "shortest",
  "attachmentFolderPath": "attachments"
}
```

- [ ] **Step 2: Create `vault/.obsidian/core-plugins.json`**

```json
{
  "file-explorer": true,
  "global-search": true,
  "graph": true,
  "backlink": true,
  "outgoing-link": true,
  "tag-pane": true,
  "outline": true,
  "word-count": true
}
```

- [ ] **Step 3: Create `vault/.obsidian/graph.json`**

```json
{
  "collapse-filter": true,
  "showTags": true,
  "showAttachments": false,
  "scale": 1,
  "close": false
}
```

- [ ] **Step 4: Create `vault/.obsidian/appearance.json`**

```json
{
  "baseFontSize": 16
}
```

- [ ] **Step 5: Commit**

```bash
git add vault/.obsidian
git commit -m "feat: Obsidian config for the Karpathy vault (graph on, core plugins)"
```

---

## Task 11: Author the Karpathy LLM Wiki notes (parallel fan-out)

**Files:**
- Create: `vault/00 — Start Here.md` and ~25–35 note files under `vault/` (see list).

**Note template (every note follows this exactly):**

```markdown
---
title: <Human Title>
tags: [<cluster-tag>, <topic-tags…>]
source: <Karpathy work, e.g. "Neural Networks: Zero to Hero — Lecture 1">
---

# <Human Title>

> One-sentence definition.

## The core idea
2–5 short paragraphs in plain language. Prefer intuition over notation; when a
formula matters, show it inline and explain each symbol.

## Why it matters / where it fits
How this connects to the bigger LLM picture.

## Related
- [[Other Note A]] — why related
- [[Other Note B]] — why related

## Source
- <Specific Karpathy video/repo + the relevant section>
```

- [ ] **Step 1: Create the index MOC `vault/00 — Start Here.md`**

```markdown
---
title: Start Here
tags: [moc]
source: Andrej Karpathy — Zero to Hero + LLM talks
---

# Start Here — Andrej Karpathy LLM Wiki

A small, interlinked study vault distilled from Andrej Karpathy's public LLM
material. Open the **graph view** (left sidebar) to explore visually.

## Maps of content
- [[Zero-to-Hero Index]] — build neural nets from scratch up to GPT
- [[LLM Index]] — how modern LLMs are trained and behave

## Suggested path
1. [[Micrograd and Backpropagation]]
2. [[Makemore — Bigram Model]] → [[Makemore — MLP]]
3. [[Lets Build GPT — Self-Attention]] → [[BPE Tokenizer]]
4. [[What Is an LLM]] → [[Pretraining]] → [[Supervised Fine-Tuning]] → [[RLHF and RL]]
```

- [ ] **Step 2: Write the two cluster MOCs**

Create `vault/Zero-to-Hero Index.md` and `vault/LLM Index.md`, each `tags: [moc]`,
linking (with `[[wikilinks]]`) to every note in their cluster from the list below.

- [ ] **Step 3: Author the notes via a parallel agent workflow**

Use the **Workflow** tool to fan out one agent per note (ultracode is on). Each
agent receives: the note title, its cluster tag, the exact template above, and the
list of sibling titles it may link to (so links resolve). Each returns the full
markdown file body. Required notes (filename = title + `.md`):

*Zero-to-Hero (`#zero-to-hero`):* `Micrograd and Backpropagation` · `Neuron, MLP, and Loss` · `Gradient Descent` · `Makemore — Bigram Model` · `Makemore — MLP` · `BatchNorm and Initialization` · `Activations and Gradients` · `Lets Build GPT — Self-Attention` · `BPE Tokenizer` · `Reproducing GPT-2`

*LLM big-picture (`#llm-overview`):* `What Is an LLM` · `Pretraining` · `Base vs Instruct Models` · `Supervised Fine-Tuning` · `RLHF and RL` · `Hallucinations and Model Psychology` · `Scaling Laws` · `Tool Use and Agents` · `Inference, Sampling, and Context Window` · `The LLM OS Analogy`

*Concept atoms (`#concept`):* `Attention` · `Softmax` · `Cross-Entropy Loss` · `Embeddings` · `Residual Stream` · `LayerNorm` · `Positional Encoding` · `Temperature and Top-k`

*MOCs (`#moc`):* `Start Here` (done) · `Zero-to-Hero Index` · `LLM Index`

- [ ] **Step 4: Write each returned note to `vault/<title>.md`**

Write every agent's output to its file. Ensure each note's `## Related` section
links only to titles that exist in the list above (no dangling links).

- [ ] **Step 5: Commit**

```bash
git add vault/*.md
git commit -m "content: Karpathy LLM Wiki notes (zero-to-hero, llm-overview, concepts, MOCs)"
```

---

## Task 12: Vault link-checker (TDD-style guard)

**Files:**
- Create: `tools/check-vault-links.sh`

- [ ] **Step 1: Implement `tools/check-vault-links.sh`**

```bash
#!/usr/bin/env bash
# Fails if any [[wikilink]] in vault/*.md points to a note that doesn't exist,
# or if a required MOC is missing. Run from repo root or anywhere.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT="${ROOT}/vault"
fail=0

# Set of existing note basenames (without .md)
existing="$(cd "$VAULT" && for f in *.md; do printf '%s\n' "${f%.md}"; done)"

# Required MOCs
for req in "Start Here" "Zero-to-Hero Index" "LLM Index"; do
  if ! grep -qxF "$req" <<<"$existing" && [[ ! -f "${VAULT}/00 — ${req}.md" ]] && [[ ! -f "${VAULT}/${req}.md" ]]; then
    echo "MISSING required MOC: ${req}"; fail=1
  fi
done

# Every [[link]] (strip alias after |, strip #heading) must resolve to a file
while IFS= read -r link; do
  base="${link%%|*}"; base="${base%%#*}"
  [[ -z "$base" ]] && continue
  if [[ ! -f "${VAULT}/${base}.md" ]] && ! grep -qxF "$base" <<<"$existing"; then
    echo "DANGLING link: [[${link}]]"; fail=1
  fi
done < <(grep -rhoE '\[\[[^]]+\]\]' "$VAULT"/*.md | sed -E 's/^\[\[//; s/\]\]$//')

if [[ "$fail" -ne 0 ]]; then echo "Vault link check FAILED"; exit 1; fi
echo "Vault link check passed"
```

- [ ] **Step 2: Run the checker**

Run: `cd ~/Documents/GitHub/claude-code-starter && bash tools/check-vault-links.sh`
Expected: `Vault link check passed`. If it reports DANGLING links, fix the offending note's `## Related` section (or add the missing note) until it passes.

- [ ] **Step 3: Commit**

```bash
git add tools/check-vault-links.sh
git commit -m "test: vault link checker (no dangling wikilinks, required MOCs)"
```

---

## Task 13: README

**Files:**
- Create: `README.md`
- Create: `LICENSE` (MIT, for Casey's original scripts + vault content)

- [ ] **Step 1: Write `README.md`**

````markdown
# claude-code-starter

One command to set up Claude Code on a fresh **Mac**, plus Obsidian with a
ready-made **Andrej Karpathy LLM wiki**, plus a curated set of starter skills.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/caseyhorowitz1536/claude-code-starter/main/bootstrap.sh | bash
```

Prefer to inspect first? Clone and run:

```bash
git clone https://github.com/caseyhorowitz1536/claude-code-starter.git
cd claude-code-starter
./setup.sh            # add --dry-run to preview, --help for options
```

## What it does
1. Installs **Homebrew** + **Xcode Command Line Tools** (if missing).
2. Installs **Claude Code** (official installer) and puts it on your PATH.
3. Installs **Obsidian** and drops the **Karpathy LLM Wiki** vault at
   `~/Documents/Karpathy LLM Wiki`.
4. Installs curated skills/plugins from their public marketplaces: **superpowers**
   (brainstorming, plans, TDD, debugging, code review…), **karpathy-guidelines**,
   and a few official plugins (`feature-dev`, `pr-review-toolkit`,
   `commit-commands`, `hookify`, `claude-code-setup`).

## After it finishes
Open a new terminal, run `claude`, then `/login` in the session (browser auth).

## Options
`--skip-obsidian` · `--skip-plugins` · `--skip-vault` · `--yes` · `--dry-run` · `--help`

## Uninstall
- Vault: `rm -rf ~/Documents/"Karpathy LLM Wiki"`
- Plugins: `claude plugin uninstall <name>` (and `claude plugin marketplace remove <name>`)
- Obsidian: `brew uninstall --cask obsidian`
- Claude Code: see the official uninstall docs.

The installer is **idempotent** (safe to re-run) and **never clobbers** an
existing vault; any shell-rc edit it makes is appended, not overwritten.
````

- [ ] **Step 2: Add an MIT `LICENSE`** (covers Casey's scripts + vault notes only; installed skills/plugins remain under their own upstream licenses).

```text
MIT License

Copyright (c) 2026 Casey Horowitz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Commit**

```bash
git add README.md LICENSE
git commit -m "docs: README (quick start, options, uninstall) + MIT license"
```

---

## Task 14: CI — shellcheck, unit tests, dry-run, vault links

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Write `.github/workflows/ci.yml`**

```yaml
name: ci
on:
  push: { branches: [main] }
  pull_request:
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: shellcheck
        run: |
          sudo apt-get update && sudo apt-get install -y shellcheck
          shellcheck setup.sh bootstrap.sh lib/*.sh tools/*.sh tests/*.sh
  unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: bash tests/run.sh
  vault:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: bash tools/check-vault-links.sh
  dryrun:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: orchestrator dry-run
        run: |
          out="$(bash setup.sh --dry-run --yes)"
          echo "$out"
          for marker in "Preflight" "Claude Code" "Obsidian" "Skills & plugins" "Karpathy LLM Wiki vault" "Done"; do
            echo "$out" | grep -q "$marker" || { echo "missing step: $marker"; exit 1; }
          done
```

- [ ] **Step 2: Resolve shellcheck findings locally (optional but recommended)**

Run: `brew install shellcheck 2>/dev/null; shellcheck setup.sh bootstrap.sh lib/*.sh tools/*.sh tests/*.sh || true`
Fix any error-level findings (warnings for intentional patterns like sourced files may be annotated with `# shellcheck disable=` and a reason).

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: shellcheck + unit + vault-link + macOS dry-run jobs"
```

---

## Task 15: Manual acceptance + go-public gate

**Files:** none (verification + publish).

- [ ] **Step 1: Full local dry-run once more**

Run: `cd ~/Documents/GitHub/claude-code-starter && bash setup.sh --dry-run --yes`
Expected: clean run, all steps, exit 0.

- [ ] **Step 2: Real acceptance on a clean macOS account (or VM)**

Run `./setup.sh` for real. Verify, in order:
- `claude --version` works in a NEW terminal.
- `/Applications/Obsidian.app` exists.
- `~/Documents/Karpathy LLM Wiki` opens in Obsidian with a populated graph.
- `claude plugin list` shows superpowers, andrej-karpathy-skills, and the official plugins.
- Re-running `./setup.sh` reports skips and changes nothing destructive.

- [ ] **Step 3: Publish the repo (enables the one-liner)**

```bash
cd ~/Documents/GitHub/claude-code-starter
gh repo create caseyhorowitz1536/claude-code-starter --public --source=. --remote=origin --push
```
Then re-confirm the one-liner end-to-end:
`curl -fsSL https://raw.githubusercontent.com/caseyhorowitz1536/claude-code-starter/main/bootstrap.sh | bash` (use `--dry-run` first by appending it after a `| bash -s --` invocation, or clone and dry-run).

- [ ] **Step 4: Final commit (if any acceptance fixes were needed)**

```bash
git add -A && git commit -m "chore: acceptance fixes" || echo "nothing to fix"
git push
```

---

## Self-Review (completed during planning)

- **Spec coverage:** preflight (§3.2)→T3; claude-code (§3.2)→T4; obsidian→T5;
  plugins/marketplaces (§5)→T6; vault copy (§3.2)→T7; orchestrator + flags + dry-run
  (§3.3)→T8; bootstrap (§3.4)→T9; vault `.obsidian` (§4)→T10; vault notes/TOC (§4)→T11;
  testing (§8)→T2/T8/T12/T14; non-goals (§6) honored (no auth, mac-only, no clobber);
  uninstall (§9)→README T13. No uncovered spec sections.
- **Placeholder scan:** all code steps contain complete, runnable code. The only
  "generated" content is the vault notes (T11), which ship a full template + MOC
  examples + an explicit note list + a link-checker (T12) that fails the build on
  any gap — not a placeholder.
- **Type/name consistency:** `do_preflight/do_claude_code/do_obsidian/do_plugins/do_vault`
  used identically in each lib and in `setup.sh main`. `run/backup/have/confirm/info/ok/warn/err/step`
  defined in `common.sh` and used everywhere. `REPO_DIR` exported by `setup.sh`, consumed by `vault.sh`.
  `DRY_RUN`/`ASSUME_YES` consistent across modules and tests.
