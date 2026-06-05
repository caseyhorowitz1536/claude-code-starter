#!/usr/bin/env bash
# Fails if any [[wikilink]] in the vault points to a note that doesn't exist, or
# if a required MOC is missing. Recurses ALL subfolders (the vault is split into
# "Karpathy LLM Wiki/" and "Using Claude Code/"); Obsidian resolves [[links]] by
# note name across the whole vault, so links are validated against basenames.
# Run from repo root or anywhere. Bash 3.2 safe (no associative arrays).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT="${ROOT}/vault"
fail=0

# Set of existing note basenames (without .md), anywhere under the vault.
# Prune .obsidian so its internal files never count as notes.
existing="$(find "$VAULT" -name '.obsidian' -prune -o -type f -name '*.md' -print \
  | while IFS= read -r f; do b="$(basename "$f")"; printf '%s\n' "${b%.md}"; done)"

# Required MOCs (matched by basename anywhere in the vault).
for req in "Start Here" "Zero-to-Hero Index" "LLM Index"; do
  if ! grep -qxF "$req" <<<"$existing"; then
    echo "MISSING required MOC: ${req}"; fail=1
  fi
done

# Every [[link]] must resolve to a note basename. We:
#   - skip backtick-wrapped examples like `[[wikilinks]]` (docs, not real links)
#   - strip a |alias and any #heading
#   - strip any Folder/ prefix (folder-qualified links used in the MOCs)
# Comparison is by basename, matching Obsidian's name-based resolution.
while IFS= read -r link; do
  base="${link%%|*}"; base="${base%%#*}"
  base="${base##*/}"                  # drop any Folder/ prefix -> basename
  # Trim leading/trailing whitespace (handles "[[Note | alias]]" spaced syntax)
  base="$(printf '%s' "$base" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  [[ -z "$base" ]] && continue
  if ! grep -qxF "$base" <<<"$existing"; then
    echo "DANGLING link: [[${link}]]"; fail=1
  fi
done < <(
  find "$VAULT" -name '.obsidian' -prune -o -type f -name '*.md' -print0 \
    | xargs -0 cat \
    | sed -E 's/`\[\[[^]]*\]\]`//g' \
    | grep -hoE '\[\[[^]]+\]\]' \
    | sed -E 's/^\[\[//; s/\]\]$//'
)

if [[ "$fail" -ne 0 ]]; then echo "Vault link check FAILED"; exit 1; fi
echo "Vault link check passed"
