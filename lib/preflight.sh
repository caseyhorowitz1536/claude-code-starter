#!/usr/bin/env bash
# do_preflight: assert macOS and ensure Xcode Command Line Tools (which provide git).
# Requires common.sh sourced first.
#
# NOTE: Homebrew is intentionally NOT required. Claude Code installs via its own
# script (~/.local/bin), plugins via the claude CLI, the vault via cp, and Obsidian
# via a direct .dmg download (see obsidian.sh) — so nothing here needs admin/sudo.

do_preflight() {
  step "Preflight"

  if [[ "$(uname -s)" != "Darwin" ]]; then
    err "This installer supports macOS only (detected $(uname -s)). Aborting."
    return 1
  fi
  ok "macOS detected ($(sw_vers -productVersion 2>/dev/null || echo '?'))"

  # Xcode Command Line Tools provide git (the one-liner needs it to clone).
  if ! xcode-select -p >/dev/null 2>&1; then
    info "Installing Xcode Command Line Tools (a GUI prompt may appear)"
    run xcode-select --install || true
    warn "If a dialog opened, finish it, then re-run this script."
  else
    ok "Xcode Command Line Tools present"
  fi
}
