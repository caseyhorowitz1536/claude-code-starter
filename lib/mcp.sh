#!/usr/bin/env bash
# do_mcp: connect the Obsidian vault to Claude Code via the official filesystem
# MCP server (read+write, no API key, no Obsidian plugin). Points the server at a
# space-free symlink to dodge spaced-path fragility. Requires common.sh first.

MCP_NAME="obsidian-vault"
# Resolve HOME-derived paths at call time (honor a per-call HOME) rather than
# freezing them at source time.
mcp_link()  { printf '%s/.claude-code-vault' "${HOME}"; }
mcp_vault() { printf '%s/Documents/Claude Code Starter' "${HOME}"; }

_mcp_add_cmd() {
  printf 'claude mcp add --scope user %s -- npx -y @modelcontextprotocol/server-filesystem "%s"' \
    "${MCP_NAME}" "$(mcp_link)"
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
  if ! have npx; then
    warn "Node/npx not found — skipping the vault↔Claude connection."
    warn "Install Node 18+ from https://nodejs.org, then run:"
    printf '   %s\n' "$(_mcp_add_cmd)"
    return 0
  fi
  if ! have claude; then
    warn "claude not on PATH — skipping MCP. After opening a new terminal, run:"
    printf '   %s\n' "$(_mcp_add_cmd)"
    return 0
  fi

  # space-free symlink (idempotent)
  if [[ ! -L "${MCP_LINK}" ]]; then
    run ln -s "${MCP_VAULT}" "${MCP_LINK}" || { warn "Could not create symlink ${MCP_LINK}"; return 0; }
  fi

  # idempotent: already registered?
  if claude mcp get "${MCP_NAME}" </dev/null >/dev/null 2>&1; then
    ok "MCP server '${MCP_NAME}' already registered"
    return 0
  fi

  info "Registering MCP server '${MCP_NAME}' (user scope)"
  if claude mcp add --scope user "${MCP_NAME}" -- \
        npx -y @modelcontextprotocol/server-filesystem "${MCP_LINK}" </dev/null; then
    ok "Vault connected to Claude Code (read+write). Try: claude mcp get ${MCP_NAME}"
  else
    warn "Automatic MCP registration failed. Run this manually:"
    printf '   %s\n' "$(_mcp_add_cmd)"
  fi
}
