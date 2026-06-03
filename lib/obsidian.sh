#!/usr/bin/env bash
# do_obsidian: install Obsidian. Primary path downloads the official .dmg and
# copies Obsidian.app into ~/Applications — NO Homebrew, NO admin/sudo. Falls back
# to Homebrew only if the direct install fails and brew happens to be present.
# Requires common.sh sourced first.

OBSIDIAN_RELEASES_JSON="https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/desktop-releases.json"

# Echo the path to an installed Obsidian.app, or nothing if not installed.
obsidian_app_path() {
  if [[ -d "/Applications/Obsidian.app" ]]; then
    echo "/Applications/Obsidian.app"
  elif [[ -d "${HOME}/Applications/Obsidian.app" ]]; then
    echo "${HOME}/Applications/Obsidian.app"
  fi
}

do_obsidian() {
  step "Obsidian"
  local existing; existing="$(obsidian_app_path)"
  if [[ -n "${existing}" ]]; then
    ok "Obsidian already installed (${existing}) — skipping"
    return 0
  fi
  if [[ "${DRY_RUN}" == "1" ]]; then
    info "[dry-run] download the latest Obsidian .dmg and copy Obsidian.app to ~/Applications"
    return 0
  fi

  if _obsidian_from_dmg; then
    ok "Obsidian installed to ~/Applications/Obsidian.app"
  elif have brew; then
    warn "Direct download failed — falling back to Homebrew"
    if run brew install --cask obsidian; then
      ok "Obsidian installed via Homebrew"
    else
      warn "Homebrew install also failed — install Obsidian manually from https://obsidian.md"
    fi
  else
    warn "Could not install Obsidian automatically. Download it from https://obsidian.md, then open the vault at ~/Documents/Karpathy LLM Wiki."
  fi
}

# Download the latest Obsidian .dmg and copy Obsidian.app into ~/Applications.
# Returns non-zero on any failure so the caller can decide on a fallback.
_obsidian_from_dmg() {
  local ver url tmp dmg mnt app rc=0
  ver="$(curl -fsSL "${OBSIDIAN_RELEASES_JSON}" 2>/dev/null \
        | sed -n 's/.*"latestVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  if [[ -z "${ver}" ]]; then warn "Could not determine the latest Obsidian version"; return 1; fi
  url="https://github.com/obsidianmd/obsidian-releases/releases/download/v${ver}/Obsidian-${ver}.dmg"

  tmp="$(mktemp -d)" || return 1
  dmg="${tmp}/Obsidian.dmg"
  mnt="${tmp}/mnt"
  mkdir -p "${mnt}"

  info "Downloading Obsidian ${ver}"
  if ! curl -fL --progress-bar "${url}" -o "${dmg}"; then
    warn "Download failed: ${url}"; rm -rf "${tmp}"; return 1
  fi
  if ! hdiutil attach "${dmg}" -nobrowse -quiet -mountpoint "${mnt}"; then
    warn "Could not mount the Obsidian disk image"; rm -rf "${tmp}"; return 1
  fi

  app="$(/bin/ls -d "${mnt}"/*.app 2>/dev/null | head -1)"
  if [[ -z "${app}" ]]; then
    warn "No .app found inside the disk image"
    hdiutil detach "${mnt}" -quiet >/dev/null 2>&1 || true
    rm -rf "${tmp}"; return 1
  fi

  mkdir -p "${HOME}/Applications"
  cp -R "${app}" "${HOME}/Applications/" || rc=1
  hdiutil detach "${mnt}" -quiet >/dev/null 2>&1 || true
  rm -rf "${tmp}"
  return "${rc}"
}
