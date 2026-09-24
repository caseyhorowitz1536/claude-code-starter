# claude-code-starter — Windows installer. Paste into PowerShell (no admin needed):
#   irm https://raw.githubusercontent.com/caseyhorowitz1536/claude-code-starter/main/install.ps1 | iex
#
# Mirrors setup.sh on macOS: Claude Code, Git, Node, Obsidian, the vault, starter
# settings, curated plugins, and the vault wired into Claude over MCP. Everything
# is per-user. Re-running is safe — it skips anything already installed.
#
# Options (env vars, since `irm | iex` can't take flags):
#   $env:CCS_SKIP_OBSIDIAN=1  $env:CCS_SKIP_PLUGINS=1  $env:CCS_REF='main'
#
# The whole script is one scriptblock so an early `return` never closes the
# user's PowerShell window (a bare `exit` under `iex` would).

& {
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Windows PowerShell 5.1 downloads crawl with the progress bar on
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Repo       = 'caseyhorowitz1536/claude-code-starter'
$Ref        = if ($env:CCS_REF) { $env:CCS_REF } else { 'main' }
$McpName    = 'obsidian-vault'
$McpPkg     = '@modelcontextprotocol/server-filesystem@2026.8.31'   # keep in sync with lib/mcp.sh
$NodeMajor  = '22'
$Docs       = [Environment]::GetFolderPath('MyDocuments')          # honors OneDrive-redirected Documents
$Vault      = Join-Path $Docs 'Claude Code Starter'
$Home_      = $env:USERPROFILE
$StarterDir = Join-Path $env:LOCALAPPDATA 'claude-code-starter'
$script:Fails = 0

function Step($m) { Write-Host "`n=== $m ===" -ForegroundColor White }
function Info($m) { Write-Host "* $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "+ $m" -ForegroundColor Green }
function Warn($m) { Write-Host "! $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "x $m" -ForegroundColor Red; $script:Fails++ }
function Have($c) { [bool](Get-Command $c -ErrorAction SilentlyContinue) }

# Put DIR on the user's PATH permanently and in this session.
function Add-UserPath($dir) {
  $user = [Environment]::GetEnvironmentVariable('Path', 'User'); if (-not $user) { $user = '' }
  if (($user -split ';') -notcontains $dir) {
    [Environment]::SetEnvironmentVariable('Path', ($dir + ';' + $user).TrimEnd(';'), 'User')
  }
  if (($env:Path -split ';') -notcontains $dir) { $env:Path = "$dir;$env:Path" }
}

# Re-read PATH from the registry (installers like winget/Git update it there).
function Refresh-Path {
  $m = [Environment]::GetEnvironmentVariable('Path', 'Machine'); $u = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = (@($u, $m, $env:Path) | Where-Object { $_ }) -join ';'
}

# Run a native command with a timeout (seconds); returns its exit code, or -1 on timeout.
function Invoke-Timed([string]$exe, [string[]]$argList, [int]$secs = 180) {
  $p = Start-Process -FilePath $exe -ArgumentList $argList -NoNewWindow -PassThru
  if (-not $p.WaitForExit($secs * 1000)) { try { $p.Kill() } catch {}; return -1 }
  return $p.ExitCode
}

# Run a native command with stderr discarded. Windows PowerShell 5.1 turns native
# stderr into a terminating error under $ErrorActionPreference='Stop', so relax it
# just for the call. $LASTEXITCODE survives for the caller.
function Quiet([scriptblock]$sb) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { & $sb 2>$null } finally { $ErrorActionPreference = $old }
}

function Test-NodeOk {
  if (-not (Have 'node.exe') -or -not (Have 'npx.cmd')) { return $false }
  $v = (Quiet { node.exe --version }) -replace '^v', ''
  return ([int]($v.Split('.')[0]) -ge 18)
}

Write-Host "Claude Code Starter (Windows) - setting up" -ForegroundColor White

# --- Preflight ------------------------------------------------------------
Step 'Preflight'
if (-not [Environment]::Is64BitOperatingSystem) { Bad 'Claude Code needs 64-bit Windows.'; return }
$arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') { 'arm64' } else { 'x64' }
Ok "Windows $([Environment]::OSVersion.Version) ($arch)"
$hasWinget = Have 'winget.exe'
if (-not $hasWinget) { Warn 'winget not found - Git will need a manual install (https://git-scm.com/downloads/win).' }

# --- Claude Code ----------------------------------------------------------
Step 'Claude Code'
$localBin = Join-Path $Home_ '.local\bin'
Add-UserPath $localBin
if (Have 'claude') {
  Ok "Claude Code already installed ($((Quiet { claude --version }) | Select-Object -First 1))"
} else {
  Info 'Installing Claude Code via the official installer'
  # Child process: the official script may `exit`, which would kill this one.
  Quiet { powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex" }
  Refresh-Path; Add-UserPath $localBin
  if (Have 'claude') { Ok 'Claude Code installed' } else { Bad 'Claude Code install failed - see https://code.claude.com/docs/en/setup'; return }
}

# --- Git (plugins clone marketplaces with git; also gives Claude its Bash tool) ---
Step 'Git'
if (Have 'git') { Ok "Git present ($((& git --version) -join ''))" }
elseif ($hasWinget) {
  Info 'Installing Git for Windows (per-user)'
  Quiet { winget.exe install --id Git.Git -e --scope user --silent --accept-source-agreements --accept-package-agreements } | Out-Null
  Refresh-Path
  if (-not (Have 'git')) {
    # No per-user package offered -> machine install (Windows may ask for permission once).
    Quiet { winget.exe install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements } | Out-Null
    Refresh-Path
  }
  if (Have 'git') { Ok 'Git installed' } else { Warn 'Git install did not finish - plugins may fail. Install from https://git-scm.com/downloads/win and re-run.' }
} else { Warn 'Skipping Git (no winget).' }

# --- Starter files (vault + settings) from the repo zip, no git needed ------
Step 'Starter files'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("ccs-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null
$zip = Join-Path $tmp 'repo.zip'
Invoke-WebRequest -UseBasicParsing "https://codeload.github.com/$Repo/zip/refs/heads/$Ref" -OutFile $zip
Expand-Archive -Path $zip -DestinationPath $tmp
$src = Get-ChildItem $tmp -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'vault') } | Select-Object -First 1
if (-not $src) { Bad 'Downloaded starter is missing its vault folder.'; return }
Ok "Downloaded starter ($Ref)"

# --- Settings (never clobber) --------------------------------------------
Step 'Claude Code settings'
$settings = Join-Path $Home_ '.claude\settings.json'
if (Test-Path $settings) { Ok 'Existing settings.json found - leaving it untouched' }
else {
  New-Item -ItemType Directory -Force -Path (Split-Path $settings) | Out-Null
  # Same allow/deny list as macOS; the statusLine is a bash one-liner, so drop it here.
  $j = Get-Content (Join-Path $src.FullName 'assets\claude-settings.json') -Raw | ConvertFrom-Json
  $j.PSObject.Properties.Remove('statusLine')
  [IO.File]::WriteAllText($settings, ($j | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding $false))
  Ok 'Starter settings installed'
}

# --- Obsidian --------------------------------------------------------------
Step 'Obsidian'
$obsExe = Join-Path $env:LOCALAPPDATA 'Programs\Obsidian\Obsidian.exe'
if ($env:CCS_SKIP_OBSIDIAN -eq '1') { Info 'Skipping Obsidian (CCS_SKIP_OBSIDIAN=1)' }
elseif (Test-Path $obsExe) { Ok 'Obsidian already installed' }
else {
  try {
    $rel = Invoke-RestMethod -UseBasicParsing 'https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/desktop-releases.json'
    $ver = $rel.latestVersion
    $exe = Join-Path $tmp "Obsidian-$ver.exe"
    Info "Downloading Obsidian $ver"
    Invoke-WebRequest -UseBasicParsing "https://github.com/obsidianmd/obsidian-releases/releases/download/v$ver/Obsidian-$ver.exe" -OutFile $exe
    $rc = Invoke-Timed $exe @('/S') 300     # per-user silent install, no admin
    if ($rc -eq 0) { Ok 'Obsidian installed' } else { Warn "Obsidian installer exited $rc - install it from https://obsidian.md" }
  } catch { Warn "Could not install Obsidian automatically ($($_.Exception.Message)) - get it from https://obsidian.md" }
}

# --- Vault (never clobber) -------------------------------------------------
Step 'Obsidian vault'
if (Test-Path $Vault) { Ok "Vault already exists at '$Vault' - leaving it untouched" }
else {
  Copy-Item -Recurse (Join-Path $src.FullName 'vault') $Vault
  Ok "Vault installed at '$Vault'"
}

# --- Plugins ---------------------------------------------------------------
Step 'Skills & plugins'
$markets = 'anthropics/claude-plugins-official', 'obra/superpowers-marketplace', 'forrestchang/andrej-karpathy-skills'
$plugins = 'superpowers@superpowers-marketplace', 'andrej-karpathy-skills@karpathy-skills',
           'claude-code-setup@claude-plugins-official', 'feature-dev@claude-plugins-official',
           'pr-review-toolkit@claude-plugins-official', 'commit-commands@claude-plugins-official',
           'hookify@claude-plugins-official', 'skill-creator@claude-plugins-official'
$claudeExe = (Get-Command claude).Source
if ($env:CCS_SKIP_PLUGINS -eq '1') { Info 'Skipping plugins (CCS_SKIP_PLUGINS=1)' }
else {
  $pf = 0
  foreach ($m in $markets) { Info "Registering marketplace $m"; if ((Invoke-Timed $claudeExe @('plugin', 'marketplace', 'add', $m) 120) -ne 0) { Warn "marketplace add failed: $m"; $pf = 1 } }
  foreach ($p in $plugins) { Info "Installing $p"; if ((Invoke-Timed $claudeExe @('plugin', 'install', $p, '--scope', 'user') 120) -ne 0) { Warn "install failed: $p"; $pf = 1 } }
  if ($pf) {
    Warn 'Some plugins failed. In a Claude Code session, run:'
    $markets | ForEach-Object { Write-Host "   /plugin marketplace add $_" }
    $plugins | ForEach-Object { Write-Host "   /plugin install $_" }
  } else { Ok 'Curated skills & plugins installed' }
}

# --- Node (the vault MCP server runs on it) --------------------------------
Step 'Node.js (for the vault MCP server)'
if (Test-NodeOk) { Ok "Node already installed ($(& node.exe --version))" }
else {
  try {
    $dist = "https://nodejs.org/dist/latest-v$NodeMajor.x"
    $sums = (Invoke-WebRequest -UseBasicParsing "$dist/SHASUMS256.txt").Content -split "`n"
    $line = $sums | Where-Object { $_ -match "node-v[\d.]+-win-$arch\.zip$" } | Select-Object -First 1
    $hash, $file = ($line.Trim() -split '\s+')
    $nz = Join-Path $tmp $file
    Info "Downloading $file"
    Invoke-WebRequest -UseBasicParsing "$dist/$file" -OutFile $nz
    if ((Get-FileHash $nz -Algorithm SHA256).Hash -ne $hash.ToUpper()) { throw 'checksum mismatch' }
    Expand-Archive -Path $nz -DestinationPath $tmp
    $nodeDir = Join-Path $StarterDir 'node'
    New-Item -ItemType Directory -Force -Path $StarterDir | Out-Null
    if (Test-Path $nodeDir) { Remove-Item -Recurse -Force $nodeDir }
    Move-Item (Join-Path $tmp ($file -replace '\.zip$', '')) $nodeDir
    Add-UserPath $nodeDir
    if (Test-NodeOk) { Ok "Node installed ($(& node.exe --version))" } else { throw 'node not runnable after install' }
  } catch { Bad "Could not install Node ($($_.Exception.Message)). Install Node LTS from https://nodejs.org and re-run." }
}

# --- MCP: connect the vault to Claude --------------------------------------
Step 'Connect vault to Claude Code (MCP)'
$addHint = "claude mcp add --scope user $McpName -- cmd /c npx -y $McpPkg `"$Vault`""
if (-not (Test-NodeOk)) { Warn "Skipping - Node is missing. After installing Node, run:`n   $addHint" }
elseif (-not (Test-Path $Vault)) { Warn "Skipping - vault not found at '$Vault'." }
else {
  # Pre-download into npx's cache without starting the server (classroom Wi-Fi).
  # npx.cmd, not npx: the npx.ps1 shim is blocked by the default execution policy.
  Info 'Pre-downloading the filesystem MCP server'
  $npx = (Get-Command npx.cmd).Source
  if ((Invoke-Timed $npx @('-y', "--package=$McpPkg", '--', 'node', '-e', '0') 180) -ne 0) { Warn 'Pre-download failed - Claude will fetch it on first launch.' }

  $existing = (Quiet { & $claudeExe mcp get $McpName }) -join "`n"
  $registered = ($LASTEXITCODE -eq 0)
  if ($registered -and $existing -like "*$McpPkg*") { Ok "MCP server '$McpName' already registered" }
  elseif ($registered -and $existing -notlike '*Claude Code Starter*') { Ok "MCP server '$McpName' already registered (custom path) - leaving it" }
  else {
    if ($registered) { Info "Updating stale MCP server '$McpName'"; Quiet { & $claudeExe mcp remove --scope user $McpName } | Out-Null }
    Info "Registering MCP server '$McpName' (user scope)"
    # Windows can't spawn npx directly (it's a .cmd), so wrap it in `cmd /c`.
    Quiet { & $claudeExe mcp add --scope user $McpName -- cmd /c npx -y $McpPkg $Vault }
    if ($LASTEXITCODE -eq 0) { Ok 'Vault connected to Claude Code (read+write)' } else { Warn "Automatic MCP registration failed. Run:`n   $addHint" }
  }
}

# --- Verify ----------------------------------------------------------------
Step 'Verify'
if (Have 'claude') { Ok 'claude on PATH' } else { Bad 'claude not on PATH - open a new PowerShell window' }
if (Test-Path $Vault) { Ok "vault present ($Vault)" } else { Bad 'vault missing - re-run the installer' }
if (Test-NodeOk) { Ok "Node present ($(& node.exe --version))" } else { Bad 'Node missing - re-run the installer' }
$null = Quiet { & $claudeExe mcp get $McpName }
if ($LASTEXITCODE -eq 0) { Ok "MCP '$McpName' registered" } else { Bad "MCP '$McpName' not registered - re-run the installer" }
if ($env:CCS_SKIP_PLUGINS -ne '1') {
  $list = (Quiet { & $claudeExe plugin list }) -join "`n"
  foreach ($p in $plugins) { $n = $p.Split('@')[0]; if ($list -like "*$n*") { Ok "plugin: $n" } else { Warn "plugin not found: $n" } }
}
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue

Step 'Done'
if ($script:Fails -eq 0) { Write-Host 'Setup complete.' -ForegroundColor Green }
else { Write-Host "Setup finished, but $($script:Fails) check(s) FAILED (see x lines above). Re-run the same command to retry." -ForegroundColor Yellow }
Write-Host @"

Last step (one-time, requires a browser):
  1. Close this window and open a NEW PowerShell window (so PATH updates apply)
  2. Run:  claude
  3. In Claude Code, log in with:  /login

Your vault is at:
  $Vault    (open it in Obsidian: 'Open folder as vault')

Re-running this installer is safe - it skips anything already installed.
"@
}
