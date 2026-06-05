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
  # Capture the full ref list first, THEN take the newest via parameter expansion.
  # Piping git straight into `head -1` closes the pipe early; under `set -o pipefail`
  # that SIGPIPEs git (exit 141) and would abort the installer before the 'main'
  # fallback. --sort=-v:refname puts the newest tag first.
  local out first
  out="$(git ls-remote --tags --refs --sort=-v:refname "${REPO_URL}" 'v*' 2>/dev/null || true)"
  [[ -n "${out}" ]] || return 0
  first="${out%%$'\n'*}"        # first (newest) line
  printf '%s\n' "${first##*/}"  # strip the refs/tags/ prefix
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

# Run main unless a test opts out (BOOTSTRAP_NO_MAIN). Invoked on the LAST line, so a
# truncated `curl | bash` download defines functions but never executes — a no-op.
# Do NOT gate on "${BASH_SOURCE[0]}" == "$0": under `curl | bash` the script is read
# from stdin, BASH_SOURCE is empty, and `set -u` would abort with
# "BASH_SOURCE[0]: unbound variable" before main ever runs.
if [[ -z "${BOOTSTRAP_NO_MAIN:-}" ]]; then
  main "$@"
fi
