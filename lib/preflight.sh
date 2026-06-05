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
    # A real install is macOS-only, but a --dry-run mutates nothing and is useful
    # for smoke-testing the orchestrator on Linux CI, so allow it there.
    if [[ "${DRY_RUN}" == "1" ]]; then
      warn "Non-macOS ($(uname -s)) detected — dry-run only; a real install is macOS-only."
      return 0
    fi
    err "This installer supports macOS only (detected $(uname -s)). Aborting."
    return 1
  fi

  # Claude Code's native app is built for macOS 13 (Ventura)+. On older macOS the
  # binary aborts at launch with a cryptic dyld error, so fail early and clearly.
  local osver major
  osver="$(sw_vers -productVersion 2>/dev/null || echo 0)"
  major="${osver%%.*}"
  if [[ "${major:-0}" -lt 13 ]]; then
    err "Claude Code needs macOS 13 (Ventura) or newer — this Mac is on ${osver}."
    err "Update macOS (Apple menu → System Settings → Software Update), then re-run."
    err "If this Mac can't update to Ventura, Claude Code can't run on it — use a newer Mac, or Claude in a browser at https://claude.ai."
    return 1
  fi
  ok "macOS detected (${osver})"

  # Xcode Command Line Tools provide git (the one-liner needs it to clone).
  if ! xcode-select -p >/dev/null 2>&1; then
    info "Installing Xcode Command Line Tools (a GUI prompt may appear)"
    run xcode-select --install || true
    warn "If a dialog opened, finish it, then re-run this script."
  else
    ok "Xcode Command Line Tools present"
  fi
}
