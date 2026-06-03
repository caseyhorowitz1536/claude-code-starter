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
