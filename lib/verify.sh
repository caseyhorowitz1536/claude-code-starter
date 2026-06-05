#!/usr/bin/env bash
# do_verify: non-mutating health check. Prints ✓/✗ per check with a remediation
# hint on failure. Returns non-zero if any CRITICAL check fails (claude/vault/mcp).
# Plugin & settings gaps are warnings (don't fail the overall result).

_VFAIL=0   # critical failures
_pass() { ok "$1"; }
_warnv() { warn "$1"; }
_failv() { err "$1"; _VFAIL=$((_VFAIL+1)); }

do_verify() {
  step "Verify"
  _VFAIL=0
  local vault="${HOME}/Documents/Claude Code Starter"
  local link="${HOME}/.claude-code-vault"

  # critical: claude
  if have claude; then _pass "claude on PATH ($(claude --version 2>/dev/null | head -1))"
  else _failv "claude not on PATH — open a new terminal, or re-run setup.sh"; fi

  # critical: vault
  if [[ -d "$vault" ]]; then _pass "vault present ($vault)"
  else _failv "vault missing — re-run setup.sh (or with --skip-mcp)"; fi
  if [[ -L "$link" ]]; then _pass "vault symlink resolves ($link)"
  else _warnv "vault symlink $link missing — MCP may be unconfigured"; fi

  # node/npx (needed for MCP)
  if have npx; then _pass "npx present"; else _warnv "npx/Node missing — needed for the vault MCP server"; fi

  # critical: mcp registered
  if have claude && claude mcp get obsidian-vault </dev/null >/dev/null 2>&1; then
    _pass "MCP 'obsidian-vault' registered"
  else
    _failv "MCP 'obsidian-vault' not registered — see README, or re-run setup.sh"
  fi

  # warnings: plugins + settings
  if have claude; then
    local p list; list="$(claude plugin list </dev/null 2>/dev/null || true)"
    for p in superpowers andrej-karpathy-skills claude-code-setup feature-dev pr-review-toolkit commit-commands hookify skill-creator; do
      case "$list" in *"$p"*) _pass "plugin: $p";; *) _warnv "plugin not found: $p (re-run setup.sh)";; esac
    done
  fi
  if [[ -f "${HOME}/.claude/settings.json" ]]; then _pass "settings.json present"
  else _warnv "no ~/.claude/settings.json (optional)"; fi

  if [[ "${_VFAIL}" -gt 0 ]]; then
    err "Verify: ${_VFAIL} critical check(s) failed."
    return 1
  fi
  ok "Verify: all critical checks passed."
  return 0
}
