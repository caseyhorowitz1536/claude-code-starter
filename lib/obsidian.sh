#!/usr/bin/env bash
# do_obsidian: install Obsidian via Homebrew cask unless already present.
# Requires common.sh + preflight (brew) first.

do_obsidian() {
  step "Obsidian"
  if [[ -d "/Applications/Obsidian.app" ]]; then
    ok "Obsidian already installed — skipping"
    return 0
  fi
  if ! have brew; then
    warn "Homebrew not available — cannot install Obsidian. Install it from https://obsidian.md and re-run with --skip-obsidian."
    return 0
  fi
  info "Installing Obsidian (brew cask)"
  run brew install --cask obsidian
}
