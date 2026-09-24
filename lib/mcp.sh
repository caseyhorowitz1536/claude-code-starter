#!/usr/bin/env bash
# do_mcp: connect the Obsidian vault to Claude Code via the official filesystem
# MCP server (read+write, no API key, no Obsidian plugin). Points the server at a
# space-free symlink to dodge spaced-path fragility. Requires common.sh first.

MCP_NAME="obsidian-vault"
# Pinned so a surprise upstream release can't break a class mid-session. Bump deliberately.
MCP_PKG="@modelcontextprotocol/server-filesystem@2026.8.31"
# Resolve HOME-derived paths at call time (honor a per-call HOME) rather than
# freezing them at source time.
mcp_link()  { printf '%s/.claude-code-vault' "${HOME}"; }
mcp_vault() { printf '%s/Documents/Claude Code Starter' "${HOME}"; }

_mcp_add_cmd() {
  printf 'claude mcp add --scope user %s -- npx -y %s "%s"' \
    "${MCP_NAME}" "${MCP_PKG}" "$(mcp_link)"
}

do_mcp() {
  step "Connect vault to Claude Code (MCP)"

  local MCP_LINK MCP_VAULT
  MCP_LINK="$(mcp_link)"
  MCP_VAULT="$(mcp_vault)"

  if [[ "${DRY_RUN}" == "1" ]]; then
    info "[dry-run] ln -s \"${MCP_VAULT}\" \"${MCP_LINK}\""
    info "[dry-run] $(_mcp_add_cmd)"
    return 0
  fi

  if [[ ! -d "${MCP_VAULT}" ]]; then
    warn "Vault not found at '${MCP_VAULT}' — skipping MCP (the server won't start without it)."
    return 0
  fi
  if ! node_ok; then
    warn "Node 18+/npx not found — skipping the vault↔Claude connection."
    warn "Install Node 18+ from https://nodejs.org, then run:"
    printf '   %s\n' "$(_mcp_add_cmd)"
    return 0
  fi
  if ! have claude; then
    warn "claude not on PATH — skipping MCP. After opening a new terminal, run:"
    printf '   %s\n' "$(_mcp_add_cmd)"
    return 0
  fi

  # space-free symlink (idempotent). A non-symlink squatting on the path would make
  # `ln -s` nest the link INSIDE it, so refuse and say why.
  if [[ -e "${MCP_LINK}" && ! -L "${MCP_LINK}" ]]; then
    warn "${MCP_LINK} exists and is not a symlink — move it aside and re-run setup."
    return 0
  fi
  # (Re)point our link at the vault if it's missing, dangling, or aimed elsewhere.
  if [[ "$(readlink "${MCP_LINK}" 2>/dev/null)" != "${MCP_VAULT}" ]]; then
    ln -sfn "${MCP_VAULT}" "${MCP_LINK}" || { warn "Could not create symlink ${MCP_LINK}"; return 0; }
  fi

  # Pre-download the server into npx's cache so Claude's first launch doesn't time
  # out fetching it (20 laptops on one classroom Wi-Fi). Runs a no-op `node -e ''`
  # instead of the server itself, so nothing is left waiting; perl caps it at 180s.
  info "Pre-downloading the filesystem MCP server"
  perl -e 'alarm shift; exec @ARGV' 180 npx -y --package="${MCP_PKG}" -- node -e '' </dev/null >/dev/null 2>&1 \
    || warn "Pre-download failed — Claude will fetch it on first launch instead."

  # idempotent: already registered with the current package + path? Otherwise a
  # stale entry from an older run is replaced so re-running setup repairs it.
  local existing
  if existing="$(claude mcp get "${MCP_NAME}" </dev/null 2>/dev/null)"; then
    if [[ "${existing}" == *"${MCP_PKG}"* && "${existing}" == *"${MCP_LINK}"* ]]; then
      ok "MCP server '${MCP_NAME}' already registered"
      return 0
    fi
    if [[ "${existing}" != *"${MCP_LINK}"* ]]; then
      # Someone pointed it at their own vault on purpose — never clobber that.
      ok "MCP server '${MCP_NAME}' already registered (custom path) — leaving it"
      return 0
    fi
    info "Updating stale MCP server '${MCP_NAME}'"
    claude mcp remove --scope user "${MCP_NAME}" </dev/null >/dev/null 2>&1 || true
  fi

  info "Registering MCP server '${MCP_NAME}' (user scope)"
  if claude mcp add --scope user "${MCP_NAME}" -- \
        npx -y "${MCP_PKG}" "${MCP_LINK}" </dev/null; then
    ok "Vault connected to Claude Code (read+write). Try: claude mcp get ${MCP_NAME}"
  else
    warn "Automatic MCP registration failed. Run this manually:"
    printf '   %s\n' "$(_mcp_add_cmd)"
  fi
}
