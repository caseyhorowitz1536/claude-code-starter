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
    printf '[dry-run] printf "\n%%s\n" %q >> %s\n' "$line" "$rc"
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
