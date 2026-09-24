# claude-code-starter

One command to set up Claude Code on a fresh **Mac**, plus Obsidian with a
ready-made vault (an **Andrej Karpathy LLM wiki** and a **Using Claude Code**
wiki) wired into Claude Code over MCP, plus a curated set of starter skills.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/caseyhorowitz1536/claude-code-starter/main/bootstrap.sh | bash
```

Short version (redirects to the same `bootstrap.sh` above — easier to type or
read over the phone):

```bash
curl -fsSL https://tinyurl.com/2actfy4c | bash
```

**Windows** (10 or 11, 64-bit) — paste into **PowerShell** (not Command Prompt).
No admin needed; it installs Claude Code, Git, Node, Obsidian, the vault, the
plugins, and the vault↔Claude MCP connection, all per-user:

```powershell
irm https://raw.githubusercontent.com/caseyhorowitz1536/claude-code-starter/main/install.ps1 | iex
```

When it finishes, close PowerShell, open a new window, run `claude`, then `/login`.
In Obsidian choose **Open folder as vault** → `Documents\Claude Code Starter`.

Prefer to inspect first? Clone and run:

```bash
git clone https://github.com/caseyhorowitz1536/claude-code-starter.git
cd claude-code-starter
./setup.sh            # add --dry-run to preview, --help for options
```

## What it does — **no admin password required**
1. Installs **Claude Code** (official installer) into `~/.local/bin` and puts it on your PATH.
2. Installs **Obsidian** by downloading the official `.dmg` straight into
   `~/Applications` (no Homebrew, no sudo) and drops a single vault at
   `~/Documents/Claude Code Starter` containing both the **Andrej Karpathy LLM
   wiki** and a **Using Claude Code** wiki (how to actually drive Claude Code:
   skills, plans, MCP, settings…).
3. **Connects the vault to Claude Code automatically** via the `obsidian-vault`
   MCP server, so Claude can read and write your notes directly (read+write, no
   API key, no Obsidian plugin). The server needs Node 18+; if you don't have it,
   setup downloads the official Node LTS from nodejs.org into `~/.local/node`
   (checksum-verified, no Homebrew, no sudo).
4. Installs a conservative starter `~/.claude/settings.json` — **only if you
   don't already have one** (it never overwrites your existing settings).
5. Installs curated skills/plugins from their public marketplaces: **superpowers**
   (brainstorming, plans, TDD, debugging, code review…), **karpathy-guidelines**,
   and a few official plugins (`feature-dev`, `pr-review-toolkit`,
   `commit-commands`, `hookify`, `claude-code-setup`, `skill-creator`).

Everything installs per-user, so you don't need to be an administrator.

**Brand-new Mac?** The first run may stop and open an Apple "Command Line Tools"
window (it provides `git`). Click **Install**, wait for it to finish (5–15 min),
then run the same command again. Teaching a group? Have everyone run
`xcode-select --install` before the session so nobody waits on it live.

## After it finishes
Open a new terminal, run `claude`, then `/login` in the session (browser auth).
Then paste the prompt from [`docs/FIRST-RUN-PROMPT.md`](docs/FIRST-RUN-PROMPT.md)
as your first message: Claude health-checks the install, tests the vault
connection end-to-end, and sets the vault up as a second brain.

To confirm everything installed correctly, run
`bash ~/.claude-code-starter/setup.sh --verify` (health checks only). To confirm the vault is wired into Claude Code, run
`claude mcp get obsidian-vault`.

## Options
`--skip-obsidian` · `--skip-plugins` · `--skip-vault` · `--skip-config` (don't
write the starter `settings.json`) · `--skip-mcp` (don't connect the vault via
MCP) · `--verify` (run health checks only, then exit) · `--yes` · `--dry-run` ·
`--help`

Set `CCS_REF=<tag>` to pin or override the release the bootstrap installs (it
defaults to the latest `v*` tag), e.g. `CCS_REF=v0.2.0 ./bootstrap.sh`.

## Uninstall
- Vault: `rm -rf ~/Documents/"Claude Code Starter"`
- Vault link (used by MCP): `rm -f ~/.claude-code-vault`
- Node (only if setup installed it): `rm -rf ~/.local/node ~/.local/bin/{node,npm,npx}`
- MCP connection: `claude mcp remove obsidian-vault`
- Plugins: `claude plugin uninstall <name>` (and `claude plugin marketplace remove <name>`)
- Obsidian: `rm -rf ~/Applications/Obsidian.app` (or `/Applications/Obsidian.app`)
- Claude Code: see the official uninstall docs.

The starter `~/.claude/settings.json` is only created if you had none, so there's
nothing to undo unless you let it write that file.

## Verify the bootstrap script
Before piping `bootstrap.sh` into your shell, you can confirm its integrity:

```bash
shasum -a 256 bootstrap.sh
# daaf5b07dfd8ce4fa637948894a3b608005a6b96857dd3c00a66f7b459f8f473  bootstrap.sh
```

The installer is **idempotent** (safe to re-run) and **never clobbers** an
existing vault; any shell-rc edit it makes is appended, not overwritten.
