#!/usr/bin/env bash
# do_claude_code: install Claude Code (native installer) and ensure it's on PATH.
# Requires common.sh sourced first.

# Pick the file a login *bash* shell on macOS will actually read. Terminal.app
# runs bash as a login shell, which reads the first existing of ~/.bash_profile,
# ~/.bash_login, ~/.profile — and ~/.bashrc is NOT read for login shells. Append
# to whichever already exists (so we don't shadow the user's ~/.profile); if none
# exist, create ~/.bash_profile.
_bash_login_rc() {
  if   [[ -f "${HOME}/.bash_profile" ]]; then printf '%s\n' "${HOME}/.bash_profile"
  elif [[ -f "${HOME}/.bash_login"   ]]; then printf '%s\n' "${HOME}/.bash_login"
  elif [[ -f "${HOME}/.profile"      ]]; then printf '%s\n' "${HOME}/.profile"
  else printf '%s\n' "${HOME}/.bash_profile"; fi
}

# Append the PATH export to rc file $1 (idempotently).
_add_path_line_to() {
  local rc="$1" line="$2"
  if [[ -f "$rc" ]] && grep -qxF "$line" "$rc"; then
    ok "$HOME/.local/bin already in ${rc}"
    return 0
  fi
  info "Adding ~/.local/bin to PATH in ${rc}"
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '[dry-run] printf "\n%%s\n" %q >> %s\n' "$line" "$rc"
  else
    printf '\n%s\n' "$line" >> "$rc"
  fi
}

_ensure_local_bin_on_path() {
  local bindir="${HOME}/.local/bin"
  local line='export PATH="$HOME/.local/bin:$PATH"'
  case ":${PATH}:" in *":${bindir}:"*) ;; *) export PATH="${bindir}:${PATH}";; esac
  # Update the rc file the user's NEXT terminal will read. macOS defaults to zsh
  # (~/.zshrc); a bash login shell needs ~/.bash_profile instead — writing only
  # to ~/.zshrc is why `claude` came up "command not found" for bash users.
  local rc
  case "${SHELL:-}" in
    *bash*) rc="$(_bash_login_rc)" ;;
    *)      rc="${HOME}/.zshrc" ;;   # zsh, or unknown -> macOS default
  esac
  _add_path_line_to "$rc" "$line"
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
