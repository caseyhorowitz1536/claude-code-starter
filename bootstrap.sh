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
