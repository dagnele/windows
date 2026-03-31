# Windows Setup Guide

Use this repo to rebuild the same Windows terminal and developer setup from scratch. The intended path is: clone the repo, run `./install.ps1`, then start a new terminal. If you want to remove it later, use `./uninstall.ps1`.

## What You Will End Up With

- a consistent terminal experience across PowerShell and `cmd.exe` in Windows Terminal
- Clink and Starship providing a shared prompt and better shell ergonomics
- Zoxide, fzf, and ripgrep available as everyday navigation and search tools
- Git installed for the development workflow

## Profiles

The setup script uses profiles to group packages. Base is always included. You can combine multiple profiles.

Packages have a `Type` of either `winget` (installed via `winget install`) or `custom` (installed via a dedicated script in `shared/packages/<Name>.ps1`).

| Profile | Packages |
|---------|----------|
| **Base** (default) | PowerShell, Git, Clink, Starship, Zoxide, fzf, ripgrep, ClinkConfig*, StarshipConfig*, ShellProfile* |
| **Neovim** | Neovim, Oh My Posh, Zig, WinLibs |
| **Obsidian** | Obsidian |
| **Browser** | Zen Browser |
| **AI** | OpenCode, OpenCodeConfig*, Memento* |
| **Rust** | Rustup |
| **CMake** | CMake |
| **LLVM** | LLVM |
| **Bun** | Bun |
| **Python** | Python 3.12 |
| **Extra** | GitHub CLI, Doppler, Tailscale |
| **LocalSend** | LocalSend |
| **PowerToys** | PowerToys |

\* = custom package (see `shared/packages/`)

## Prerequisites

- Windows 10 or Windows 11
- [WinGet](https://learn.microsoft.com/windows/package-manager/winget/) available in PowerShell
- A checkout location such as `C:\src`

## Neovim Profile (NeoVim Development)

If you plan to develop with NeoVim (building from source, tree-sitter parsers, etc.), include the Neovim profile:

```powershell
pwsh -ExecutionPolicy Bypass -File .\install.ps1 -InstallProfile Neovim
```

This installs:
- **Neovim** - Modern Vim fork
- **Oh My Posh** - Terminal theme engine with prompt customization
- **Zig** - Build dependency for compiling NeoVim
- **WinLibs** - GCC toolchain for native builds

Note: **tree-sitter-cli** requires Rust. Install with:
```powershell
cargo install tree-sitter-cli
```
Or use the Rust profile: `-InstallProfile Neovim,Rust`

### NeoVim Setup Notes

1. **Oh My Posh**: Run `oh-my-posh font install` in PowerShell to install Nerd Fonts.

2. **Font Configuration**: Configure Windows Terminal to use the new font in Settings → Appearance → Font face (e.g., FiraCode Nerd Font).

3. **LazyVim**: A pre-configured NeoVim distribution. Install by backing up your config and cloning the starter:
   ```powershell
   mv $env:LOCALAPPDATA\nvim $env:LOCALAPPDATA\nvim.bak
   git clone https://github.com/LazyVim/starter $env:LOCALAPPDATA\nvim
   ```
   Restart NeoVim and run `:LazySync` to install plugins.

## Browser Profile

If you want Zen Browser with recommended extensions, include the Browser profile:

```powershell
pwsh -ExecutionPolicy Bypass -File .\install.ps1 -InstallProfile Browser
```

### Recommended Extensions

Install these extensions from Firefox Add-ons:

- [uBlock Origin](https://addons.mozilla.org/en-us/firefox/addon/ublock-origin/) - Ad blocker
- [Tampermonkey](https://addons.mozilla.org/en-US/firefox/addon/tampermonkey/) - Userscript manager
- [Bitwarden](https://addons.mozilla.org/firefox/addon/bitwarden-password-manager) - Password manager
- [Unhook](https://addons.mozilla.org/en-US/firefox/addon/youtube-recommended-videos/) - Remove YouTube recommendations and shorts

## 1. Clone This Repo

```powershell
New-Item -ItemType Directory -Force C:\src | Out-Null
git clone <your-repo-url> C:\src\windows.git
cd C:\src\windows.git
```

## 2. Run the Setup Script

Install with the Base profile (default):

```powershell
pwsh -ExecutionPolicy Bypass -File .\install.ps1
```

Install with additional profiles:

```powershell
pwsh -ExecutionPolicy Bypass -File .\install.ps1 -InstallProfile AI,Rust
```

Dry run:

```powershell
pwsh -ExecutionPolicy Bypass -File .\install.ps1 -WhatIf
```

## What `install.ps1` Does

- installs `winget` packages for the selected profiles
- runs custom package scripts from `shared/packages/` for any `custom` type entries
- configures user PATH for profiles that require it

Base is always included even when you only specify other profiles.

After the script finishes, restart PowerShell, Windows Terminal, and any open `cmd.exe` sessions.

## PowerShell Profile

The script appends the following snippet to your PowerShell profile (`$PROFILE`). Clink is not needed here -- it only applies to `cmd.exe`.

```powershell
# Starship
Invoke-Expression (&"starship.exe" init powershell)

# Zoxide
Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell | Out-String)
})
```

## Verify the Setup

Run these checks:

```powershell
starship --version
zoxide --version
git --version
fzf --version
rg --version
```

Then verify behavior:

- open PowerShell and confirm the Starship prompt appears
- open `cmd.exe` and confirm the Starship prompt appears there too
- run `z` after changing directories a few times
- in `cmd.exe`, try `z foo`, `z -l foo`, `zi foo`, `z ..`, and `z -`
- in `cmd.exe`, run `z --help` to see the custom Clink wrapper usage
- run `starship explain` to inspect the active prompt configuration

## Day-to-Day Usage

- use `z project-name` to jump to a frequent directory
- use `z --help` in `cmd.exe` to see available wrapper commands
- use `zi` for interactive Zoxide selection in `cmd.exe`
- use `z -l term` in `cmd.exe` to list ranked matches without changing directory
- use `z ..`, `z -`, `z .\path`, or `z C:\path` in `cmd.exe` for direct navigation shortcuts
- edit `C:\src\windows.git\.starship\config.toml` to tune the prompt
- edit `C:\src\windows.git\.clink\zoxide.lua` to change `cmd.exe` Zoxide behavior

## Updating

Pull the latest repo changes, then rerun the setup script:

```powershell
git pull
pwsh -ExecutionPolicy Bypass -File .\install.ps1
```

To include additional profiles:

```powershell
pwsh -ExecutionPolicy Bypass -File .\install.ps1 -InstallProfile AI,Rust
```

`winget install` will reuse existing packages and upgrade them when newer versions are available.

## Troubleshooting

- Starship does not appear in `cmd.exe`: confirm `%LOCALAPPDATA%\clink\startship.lua` exists and `starship.exe` is on `PATH`
- Starship does not appear in PowerShell: confirm your PowerShell profile includes the Starship init block added by `install.ps1`
- `z` does not work: open a new shell after installing Zoxide so `PATH` is refreshed
- `zi` does not work interactively: confirm `fzf` is installed and available on `PATH`
- icons look wrong: install a Nerd Font and select it in Windows Terminal
- colors or prompt rendering look wrong: use Windows Terminal or a recent console host with UTF-8 and VT support

## Uninstall

Remove Base profile packages and deployed config:

```powershell
pwsh -ExecutionPolicy Bypass -File .\uninstall.ps1
```

Remove specific profiles:

```powershell
pwsh -ExecutionPolicy Bypass -File .\uninstall.ps1 -InstallProfile Extra
```

Remove everything:

```powershell
pwsh -ExecutionPolicy Bypass -File .\uninstall.ps1 -All
```

Dry run:

```powershell
pwsh -ExecutionPolicy Bypass -File .\uninstall.ps1 -WhatIf
```

## License

See [LICENSE](LICENSE).
