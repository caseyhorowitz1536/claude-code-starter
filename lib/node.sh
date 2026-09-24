#!/usr/bin/env bash
# do_node: make sure Node 18+ (node + npx) is available — the vault MCP server
# runs via npx. A fresh Mac has no Node, so without this the MCP step is skipped.
# Installs the official nodejs.org LTS tarball per-user into ~/.local/node and
# symlinks node/npm/npx into ~/.local/bin (already on PATH via claude-code.sh).
# NO Homebrew, NO sudo. The download is verified against nodejs.org's SHASUMS256.
# Requires common.sh sourced first.

NODE_MAJOR="22"   # active LTS line
NODE_DIST="https://nodejs.org/dist/latest-v${NODE_MAJOR}.x"

# node_ok -> 0 if node >= 18 and npx are on PATH
node_ok() {
  have node && have npx || return 1
  local v; v="$(node --version 2>/dev/null)"; v="${v#v}"
  [[ "${v%%.*}" =~ ^[0-9]+$ ]] && [[ "${v%%.*}" -ge 18 ]]
}

do_node() {
  step "Node.js (for the vault MCP server)"
  if node_ok; then
    ok "Node already installed ($(node --version), $(command -v node))"
    return 0
  fi
  if [[ "${DRY_RUN}" == "1" ]]; then
    info "[dry-run] download Node ${NODE_MAJOR} LTS from nodejs.org into ~/.local/node and link node/npm/npx into ~/.local/bin"
    return 0
  fi
  if _node_from_tarball; then
    ok "Node installed ($(node --version)) at ~/.local/node"
  else
    warn "Could not install Node automatically. Install Node 18+ from https://nodejs.org, then re-run setup."
  fi
}

_node_from_tarball() {
  local arch sums file tmp prefix="${HOME}/.local/node" bindir="${HOME}/.local/bin" b
  case "$(uname -m)" in
    arm64)  arch="arm64" ;;
    x86_64) arch="x64" ;;
    *) warn "Unsupported CPU $(uname -m) for the Node download"; return 1 ;;
  esac

  sums="$(curl -fsSL "${NODE_DIST}/SHASUMS256.txt" 2>/dev/null)" || { warn "Could not reach nodejs.org"; return 1; }
  file="$(printf '%s\n' "${sums}" | awk -v a="darwin-${arch}.tar.gz" '$2 ~ a"$" {print $2; exit}')"
  [[ -n "${file}" ]] || { warn "No macOS ${arch} Node build found"; return 1; }

  tmp="$(mktemp -d)" || return 1
  info "Downloading ${file}"
  if ! curl -fL --progress-bar "${NODE_DIST}/${file}" -o "${tmp}/${file}"; then
    warn "Node download failed"; rm -rf "${tmp}"; return 1
  fi
  if ! (cd "${tmp}" && printf '%s\n' "${sums}" | grep "  ${file}\$" | shasum -a 256 -c - >/dev/null 2>&1); then
    warn "Node download failed its checksum — not installing it"; rm -rf "${tmp}"; return 1
  fi
  if ! tar -xzf "${tmp}/${file}" -C "${tmp}"; then
    warn "Could not unpack Node"; rm -rf "${tmp}"; return 1
  fi

  # Swap in the new install only once it's fully unpacked.
  rm -rf "${prefix}"
  mkdir -p "${HOME}/.local" "${bindir}"
  mv "${tmp}/${file%.tar.gz}" "${prefix}" || { rm -rf "${tmp}"; return 1; }
  rm -rf "${tmp}"
  for b in node npm npx; do ln -sf "${prefix}/bin/${b}" "${bindir}/${b}"; done
  case ":${PATH}:" in *":${bindir}:"*) ;; *) export PATH="${bindir}:${PATH}";; esac
  hash -r
  node_ok
}
