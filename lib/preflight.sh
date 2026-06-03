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

  # Homebrew — only needed for Obsidian, so skip it entirely when Obsidian is skipped.
  local brew_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
  if [[ "${SKIP_OBSIDIAN:-0}" == "1" ]]; then
    info "Skipping Homebrew (only needed for Obsidian, which is being skipped)"
  elif have brew; then
    ok "Homebrew present"
  else
    info "Installing Homebrew"
    if [[ "${DRY_RUN}" == "1" ]]; then
      # shellcheck disable=SC2016  # literal dry-run preview text; must NOT expand
      printf '[dry-run] /bin/bash -c "$(curl -fsSL %s)"\n' "$brew_url"
    elif [[ "${ASSUME_YES}" == "1" ]] || ! { true >/dev/tty; } 2>/dev/null; then
      # Automation/CI: no terminal to type a password into — needs passwordless sudo.
      info "Non-interactive mode — Homebrew install relies on passwordless sudo here."
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$brew_url")"
    else
      # Interactive user: let Homebrew prompt for the admin password. Read from
      # /dev/tty so prompts work even when this script is run via `curl | bash`.
      warn "Homebrew needs your Mac login password next (you must be an administrator)."
      /bin/bash -c "$(curl -fsSL "$brew_url")" </dev/tty
    fi
  fi

  # Resolve brew prefix (Apple Silicon /opt/homebrew vs Intel /usr/local) and load
  # it into this process — only if Homebrew is actually present.
  if have brew; then
    BREW_PREFIX="$(brew --prefix)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    BREW_PREFIX=/opt/homebrew
  elif [[ -x /usr/local/bin/brew ]]; then
    BREW_PREFIX=/usr/local
  else
    BREW_PREFIX=""
  fi
  if [[ -n "${BREW_PREFIX}" ]]; then
    export BREW_PREFIX
    eval "$("${BREW_PREFIX}/bin/brew" shellenv)" 2>/dev/null || true
    ok "Homebrew prefix: ${BREW_PREFIX}"
  fi
}
