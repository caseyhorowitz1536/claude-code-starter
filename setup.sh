#!/usr/bin/env bash
# claude-code-starter — one-shot macOS onboarding orchestrator.
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export REPO_DIR

# Defaults (overridable by flags)
DRY_RUN=0; ASSUME_YES=0
SKIP_OBSIDIAN=0; SKIP_PLUGINS=0; SKIP_VAULT=0; SKIP_CONFIG=0; SKIP_MCP=0; VERIFY_ONLY=0; HELP_ONLY=0

usage() {
  cat <<'EOF'
Usage: setup.sh [options]
  --skip-obsidian   Don't install Obsidian
  --skip-plugins    Don't install skills/plugins
  --skip-vault      Don't install the Karpathy vault
  --skip-config     Don't write the starter settings.json
  --skip-mcp        Don't connect the vault via MCP
  --verify          Run post-install health checks only, then exit
  --yes             Non-interactive (assume yes to prompts)
  --dry-run         Log intended actions without changing anything
  --help            Show this help
EOF
}

parse_args() {
  DRY_RUN=0; ASSUME_YES=0; SKIP_OBSIDIAN=0; SKIP_PLUGINS=0; SKIP_VAULT=0; SKIP_CONFIG=0; SKIP_MCP=0; VERIFY_ONLY=0; HELP_ONLY=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-obsidian) SKIP_OBSIDIAN=1 ;;
      --skip-plugins)  SKIP_PLUGINS=1 ;;
      --skip-vault)    SKIP_VAULT=1 ;;
      --skip-config)   SKIP_CONFIG=1 ;;
      --skip-mcp)      SKIP_MCP=1 ;;
      --verify)        VERIFY_ONLY=1 ;;
      --yes|-y)        ASSUME_YES=1 ;;
      --dry-run)       DRY_RUN=1 ;;
      --help|-h)       HELP_ONLY=1 ;;
      *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; return 2 ;;
    esac
    shift
  done
  export DRY_RUN ASSUME_YES SKIP_OBSIDIAN SKIP_PLUGINS SKIP_VAULT SKIP_CONFIG SKIP_MCP VERIFY_ONLY HELP_ONLY
}

main() {
  parse_args "$@"
  # --help must NOT fall through into the installer (print usage and stop).
  if [[ "${HELP_ONLY}" == "1" ]]; then usage; return 0; fi
  # shellcheck source=/dev/null
  source "${REPO_DIR}/lib/common.sh"
  for m in preflight claude-code obsidian plugins vault config mcp verify; do
    # shellcheck source=/dev/null
    source "${REPO_DIR}/lib/${m}.sh"
  done

  if [[ "${VERIFY_ONLY}" == "1" ]]; then do_verify; return $?; fi

  cleanup() {
    local rc=$?
    if [[ $rc -ne 0 ]]; then
      err "setup failed (exit ${rc}). Nothing was left half-installed by this run."
      err "Re-running is safe — it skips anything already installed."
    fi
  }
  trap cleanup EXIT

  printf '%s\n' "${C_BOLD}Claude Code Starter${C_RESET} — setting up your terminal"
  [[ "${DRY_RUN}" == "1" ]] && warn "DRY RUN — no changes will be made"

  do_preflight
  do_claude_code
  if [[ "${SKIP_CONFIG}"   == "1" ]]; then info "Skipping settings (--skip-config)"; else do_config; fi
  if [[ "${SKIP_OBSIDIAN}" == "1" ]]; then info "Skipping Obsidian (--skip-obsidian)"; else do_obsidian; fi
  if [[ "${SKIP_PLUGINS}"  == "1" ]]; then info "Skipping plugins (--skip-plugins)"; else do_plugins; fi
  if [[ "${SKIP_VAULT}"    == "1" ]]; then info "Skipping vault (--skip-vault)"; else do_vault; fi
  if [[ "${SKIP_MCP}"      == "1" ]]; then info "Skipping MCP (--skip-mcp)"; else do_mcp; fi
  do_verify || warn "Some post-install checks failed — run 'setup.sh --verify' for details."

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

Your Claude Code vault is at:
  ~/Documents/Claude Code Starter    (open it in Obsidian)

To check everything installed correctly, run:
  setup.sh --verify

Re-running this script is safe — it skips anything already installed.
EOF
}

# Only run main when executed, not when sourced (so tests can call parse_args).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
