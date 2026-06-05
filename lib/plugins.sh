#!/usr/bin/env bash
# do_plugins: register curated marketplaces and install curated plugins headlessly.
# Hard-require path: claude plugin marketplace add + install. On any failure,
# fall back to printing a manual /plugin checklist. Requires common.sh first.

# "repo|marketplace-name"
MARKETPLACES=(
  "anthropics/claude-plugins-official|claude-plugins-official"
  "obra/superpowers-marketplace|superpowers-marketplace"
  "forrestchang/andrej-karpathy-skills|karpathy-skills"
)
# "plugin@marketplace-name"
PLUGINS=(
  "superpowers@superpowers-marketplace"
  "andrej-karpathy-skills@karpathy-skills"
  "claude-code-setup@claude-plugins-official"
  "feature-dev@claude-plugins-official"
  "pr-review-toolkit@claude-plugins-official"
  "commit-commands@claude-plugins-official"
  "hookify@claude-plugins-official"
  "skill-creator@claude-plugins-official"
)

# Run a claude subcommand non-interactively: no stdin (so a trust prompt can't
# hang), bounded by timeout. Returns the command's exit code.
_claude() {
  local t="timeout"; have timeout || t="" # gtimeout/none on some macs; degrade gracefully
  if [[ "${DRY_RUN}" == "1" ]]; then printf '[dry-run] claude %s\n' "$*"; return 0; fi
  if [[ -n "$t" ]]; then ${t} 120 claude "$@" </dev/null; else claude "$@" </dev/null; fi
}

_print_manual_checklist() {
  warn "Falling back to a manual checklist. In a Claude Code session, run:"
  local m p
  for m in "${MARKETPLACES[@]}"; do printf '   /plugin marketplace add %s\n' "${m%%|*}"; done
  for p in "${PLUGINS[@]}"; do printf '   /plugin install %s\n' "$p"; done
}

do_plugins() {
  step "Skills & plugins"
  if [[ "${DRY_RUN}" != "1" ]] && ! have claude; then
    warn "claude not on PATH — skipping automated plugin install."
    _print_manual_checklist
    return 0
  fi

  local failed=0 entry repo
  for entry in "${MARKETPLACES[@]}"; do
    repo="${entry%%|*}"
    info "Registering marketplace ${repo}"
    _claude plugin marketplace add "${repo}" || { warn "marketplace add failed: ${repo}"; failed=1; }
  done

  local p
  for p in "${PLUGINS[@]}"; do
    info "Installing ${p}"
    _claude plugin install "${p}" --scope user || { warn "install failed: ${p}"; failed=1; }
  done

  if [[ "${failed}" -eq 1 ]]; then
    _print_manual_checklist
  else
    ok "Curated skills & plugins installed"
  fi
}
