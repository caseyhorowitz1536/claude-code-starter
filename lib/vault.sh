#!/usr/bin/env bash
# do_vault: copy the bundled vault to ~/Documents/Claude Code Starter/ (never clobber).
# Requires common.sh first. Expects $REPO_DIR to point at the repo root.

VAULT_DEST="${HOME}/Documents/Claude Code Starter"

do_vault() {
  step "Obsidian vault"
  local src="${REPO_DIR}/vault"
  local dest="${HOME}/Documents/Claude Code Starter"
  if [[ ! -d "$src" ]]; then err "bundled vault missing at ${src}"; return 1; fi

  if [[ -d "$dest" ]]; then
    ok "Vault already exists at '${dest}' — leaving it untouched"
  else
    info "Installing vault to '${dest}'"
    run mkdir -p "${HOME}/Documents"
    run cp -R "$src" "$dest"
    ok "Vault installed"
  fi

  local obs=""
  [[ -d "/Applications/Obsidian.app" ]] && obs="/Applications/Obsidian.app"
  [[ -z "$obs" && -d "${HOME}/Applications/Obsidian.app" ]] && obs="${HOME}/Applications/Obsidian.app"
  if [[ "${DRY_RUN}" != "1" ]] && [[ -n "$obs" ]] && confirm "Open the vault in Obsidian now?"; then
    # Opening the app is a nicety — never let it fail the installer.
    run open -a "$obs" "$dest" || warn "Could not open Obsidian automatically — open the vault manually."
  fi
}
