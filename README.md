# Windows Setup Guide

Use this repo as a step-by-step guide for rebuilding the same Windows terminal and developer setup from scratch, using the default config locations documented by Clink and Starship.

The base setup uses:

- Clink for a better `cmd.exe` experience
- Starship for the prompt
- Zoxide for fast directory jumping
- fzf for interactive fuzzy selection
- ripgrep for fast recursive search
- Windows Terminal and PowerShell for daily shell work
- Git, GitHub CLI, and OpenCode for development workflow

Optional tools in this setup:

- CMake
- LLVM
- Bun
- Rustup
- Doppler
- Tailscale

## What You Will End Up With

- Windows Terminal as the main terminal app
- PowerShell 7 installed alongside `cmd.exe`
- Clink customizing `cmd.exe`
- Starship prompt in `cmd.exe` and PowerShell
- Zoxide available as `z`
- `fzf` available for interactive pickers
- `rg` available for fast search
- Clink Lua scripts in `%LOCALAPPDATA%\clink`
- Starship config in `$HOME\.config\starship.toml`

## Prerequisites

- Windows 10 or Windows 11
- [WinGet](https://learn.microsoft.com/windows/package-manager/winget/) available in PowerShell
- A Git checkout location such as `C:\src`

## 1. Install Core Apps

Run these commands in PowerShell:

```powershell
winget install --id Microsoft.WindowsTerminal -e
winget install --id Microsoft.PowerShell -e
winget install --id Git.Git -e
winget install --id GitHub.cli -e
winget install --id SST.OpenCodeDesktop -e
winget install --id chrisant996.Clink -e
winget install --id Starship.Starship -e
winget install --id ajeetdsouza.zoxide -e
winget install --id junegunn.fzf -e
winget install --id BurntSushi.ripgrep.MSVC -e
```

Optional tools:

```powershell
winget install --id Kitware.CMake -e
winget install --id LLVM.LLVM -e
winget install --id Oven-sh.Bun -e
winget install --id Rustlang.Rustup -e
winget install --id Doppler.doppler -e
winget install --id Tailscale.Tailscale -e
```

After installation, close and reopen PowerShell or Windows Terminal.

## 2. Clone This Repo

Example:

```powershell
New-Item -ItemType Directory -Force C:\src | Out-Null
git clone <your-repo-url> C:\src\windows.git
cd C:\src\windows.git
```

If you already copied the files locally, just open the repo root and continue.

## 3. Bootstrap Automatically

The easiest path is to run the setup script from the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

To include optional tools:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -OptionalPackages CMake,LLVM,Bun
```

Dry run:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -WhatIf
```

The script will:

- install the core packages with `winget`
- install any selected optional packages
- copy `.clink` into `%LOCALAPPDATA%\clink`
- copy `.starship\config.toml` into `$HOME\.config\starship.toml`
- append Starship and Zoxide initialization to your PowerShell profile if it is not already present

## 4. Deploy the Config Files Manually

If you do not want to use `setup.ps1`, deploy the repo files yourself.

This repo contains:

```text
.clink\startship.lua
.clink\zoxide.lua
.starship\config.toml
```

Copy Clink Lua scripts to Clink's default profile directory:

```powershell
New-Item -ItemType Directory -Force "$env:LOCALAPPDATA\clink" | Out-Null
Copy-Item -Recurse -Force .clink\* "$env:LOCALAPPDATA\clink"
```

Copy Starship config to Starship's default config path:

```powershell
New-Item -ItemType Directory -Force "$HOME\.config" | Out-Null
Copy-Item -Force .starship\config.toml "$HOME\.config\starship.toml"
```

## 5. Configure PowerShell

PowerShell still needs to load Starship and Zoxide from your profile.

Open your PowerShell profile:

```powershell
if (!(Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}
notepad $PROFILE
```

Add this:

```powershell
Invoke-Expression (&"starship.exe" init powershell)

Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell | Out-String)
})
```

Save the file, then restart PowerShell.

## 6. How `cmd.exe` Gets Configured

Clink loads Lua scripts from its profile directory, which by default is `%LOCALAPPDATA%\clink`.

In this repo:

- `.clink/startship.lua` loads the Starship prompt into `cmd.exe`
- `.clink/zoxide.lua` adds `z`, `zi`, and automatic directory tracking for Zoxide
- `.starship/config.toml` defines the Starship prompt configuration

Once the files are in place, open a fresh `cmd.exe` or Windows Terminal tab using Command Prompt.

## 7. Verify the Setup

Run these checks:

```powershell
starship --version
zoxide --version
git --version
gh --version
fzf --version
rg --version
```

Then verify behavior:

- Open PowerShell and confirm the Starship prompt appears
- Open `cmd.exe` and confirm the Starship prompt appears there too
- Run `z` after changing directories a few times
- In `cmd.exe`, try `z foo`, `z -l foo`, `zi foo`, `z ..`, and `z -`
- In `cmd.exe`, run `z --help` to see the custom Clink wrapper usage
- Run `starship explain` to inspect the active prompt configuration

## 8. Day-to-Day Usage

- Use `z project-name` to jump to a frequent directory
- Use `z --help` in `cmd.exe` to see available wrapper commands
- Use `zi` for interactive Zoxide selection in `cmd.exe`
- Use `z -l term` in `cmd.exe` to list ranked matches without changing directory
- Use `z ..`, `z -`, `z .\path`, or `z C:\path` in `cmd.exe` for direct navigation shortcuts
- Edit `C:\src\windows.git\.starship\config.toml` to tune the prompt
- Edit `C:\src\windows.git\.clink\zoxide.lua` to change `cmd.exe` Zoxide behavior
- Restart the shell after config changes

## Updating

Update installed apps:

```powershell
winget upgrade --id Microsoft.WindowsTerminal -e
winget upgrade --id Microsoft.PowerShell -e
winget upgrade --id Git.Git -e
winget upgrade --id GitHub.cli -e
winget upgrade --id SST.OpenCodeDesktop -e
winget upgrade --id chrisant996.Clink -e
winget upgrade --id Starship.Starship -e
winget upgrade --id ajeetdsouza.zoxide -e
winget upgrade --id junegunn.fzf -e
winget upgrade --id BurntSushi.ripgrep.MSVC -e
```

Optional tools:

```powershell
winget upgrade --id Kitware.CMake -e
winget upgrade --id LLVM.LLVM -e
winget upgrade --id Oven-sh.Bun -e
winget upgrade --id Rustlang.Rustup -e
winget upgrade --id Doppler.doppler -e
winget upgrade --id Tailscale.Tailscale -e
```

Then pull the latest repo changes and rerun `setup.ps1`, or manually recopy the config files.

## Troubleshooting

- Starship does not appear in `cmd.exe`: confirm `%LOCALAPPDATA%\clink\startship.lua` exists and `starship.exe` is on `PATH`
- Starship does not appear in PowerShell: confirm your PowerShell profile includes the `starship init powershell` block
- `z` does not work: open a new shell after installing Zoxide so `PATH` is refreshed
- Icons look wrong: install a Nerd Font and select it in Windows Terminal
- Colors or prompt rendering look wrong: use Windows Terminal or a recent console host with UTF-8 and VT support

## Uninstall

```powershell
winget uninstall --id chrisant996.Clink -e
winget uninstall --id Starship.Starship -e
winget uninstall --id ajeetdsouza.zoxide -e
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\clink"
Remove-Item -Force "$HOME\.config\starship.toml" -ErrorAction SilentlyContinue
```

Remove the Starship and Zoxide lines from your PowerShell profile if you added them.

## License

See [LICENSE](LICENSE).
