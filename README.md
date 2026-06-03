# claude-code-starter

One command to set up Claude Code on a fresh **Mac**, plus Obsidian with a
ready-made **Andrej Karpathy LLM wiki**, plus a curated set of starter skills.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/caseyhorowitz1536/claude-code-starter/main/bootstrap.sh | bash
```

Prefer to inspect first? Clone and run:

```bash
git clone https://github.com/caseyhorowitz1536/claude-code-starter.git
cd claude-code-starter
./setup.sh            # add --dry-run to preview, --help for options
```

## What it does — **no admin password required**
1. Installs **Claude Code** (official installer) into `~/.local/bin` and puts it on your PATH.
2. Installs **Obsidian** by downloading the official `.dmg` straight into
   `~/Applications` (no Homebrew, no sudo) and drops the **Karpathy LLM Wiki**
   vault at `~/Documents/Karpathy LLM Wiki`.
3. Installs curated skills/plugins from their public marketplaces: **superpowers**
   (brainstorming, plans, TDD, debugging, code review…), **karpathy-guidelines**,
   and a few official plugins (`feature-dev`, `pr-review-toolkit`,
   `commit-commands`, `hookify`, `claude-code-setup`).

Everything installs per-user, so you don't need to be an administrator. (On a
truly fresh Mac it may install Xcode Command Line Tools — a one-time GUI click —
to provide `git`.)

## After it finishes
Open a new terminal, run `claude`, then `/login` in the session (browser auth).

## Options
`--skip-obsidian` · `--skip-plugins` · `--skip-vault` · `--yes` · `--dry-run` · `--help`

## Uninstall
- Vault: `rm -rf ~/Documents/"Karpathy LLM Wiki"`
- Plugins: `claude plugin uninstall <name>` (and `claude plugin marketplace remove <name>`)
- Obsidian: `rm -rf ~/Applications/Obsidian.app` (or `/Applications/Obsidian.app`)
- Claude Code: see the official uninstall docs.

The installer is **idempotent** (safe to re-run) and **never clobbers** an
existing vault; any shell-rc edit it makes is appended, not overwritten.
