#!/usr/bin/env bash
# do_vault: copy the bundled vault to ~/Documents/Karpathy LLM Wiki/ (never clobber).
# Requires common.sh first. Expects $REPO_DIR to point at the repo root.

VAULT_DEST="${HOME}/Documents/Karpathy LLM Wiki"

do_vault() {
  step "Karpathy LLM Wiki vault"
  local src="${REPO_DIR}/vault"
  if [[ ! -d "$src" ]]; then err "bundled vault missing at ${src}"; return 1; fi

  if [[ -d "$VAULT_DEST" ]]; then
    ok "Vault already exists at '${VAULT_DEST}' — leaving it untouched"
  else
    info "Installing vault to '${VAULT_DEST}'"
    run mkdir -p "${HOME}/Documents"
    run cp -R "$src" "$VAULT_DEST"
    ok "Vault installed"
  fi

  if [[ "${DRY_RUN}" != "1" ]] && [[ -d "/Applications/Obsidian.app" ]] && confirm "Open the vault in Obsidian now?"; then
    run open -a Obsidian "$VAULT_DEST"
  fi
}
