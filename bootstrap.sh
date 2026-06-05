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
