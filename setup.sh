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
