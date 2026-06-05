#!/usr/bin/env bash
# do_config: install a conservative starter ~/.claude/settings.json — ONLY if the
# user has none (never clobber). Requires common.sh sourced first; expects $REPO_DIR.

do_config() {
  step "Claude Code settings"
  local dest="${HOME}/.claude/settings.json"
  local src="${REPO_DIR}/assets/claude-settings.json"

  if [[ ! -f "$src" ]]; then warn "starter settings asset missing at ${src}"; return 0; fi
  if [[ -f "$dest" ]]; then
    ok "Existing ${dest} found — leaving it untouched"
    return 0
  fi
  info "Installing starter settings to ${dest}"
  run mkdir -p "${HOME}/.claude"
  run cp "$src" "$dest"
  ok "Starter settings installed (safe read-only allow-list + statusline; no model/hooks)"
}
