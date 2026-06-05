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
