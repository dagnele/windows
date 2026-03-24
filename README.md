# Windows Setup Guide

Use this repo to rebuild the same Windows terminal and developer setup from scratch. The intended path is: clone the repo, run `./setup.ps1`, then start a new terminal. If you want to remove it later, use `./uninstall.ps1`.

## What This Sets Up

- Windows Terminal and PowerShell for daily shell work
- Clink for a better `cmd.exe` experience
- Starship for the prompt
- Zoxide for fast directory jumping
- fzf for interactive fuzzy selection
- ripgrep for fast recursive search
- Git, GitHub CLI, and OpenCode for development workflow

Optional packages supported by the setup script:

- CMake
- LLVM
- Bun
- Rustup
- Doppler
- Tailscale

## Prerequisites

- Windows 10 or Windows 11
- [WinGet](https://learn.microsoft.com/windows/package-manager/winget/) available in PowerShell
- A checkout location such as `C:\src`

## 1. Clone This Repo

```powershell
New-Item -ItemType Directory -Force C:\src | Out-Null
git clone <your-repo-url> C:\src\windows.git
cd C:\src\windows.git
```

## 2. Run the Setup Script

Install the default setup:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

Install the default setup plus selected optional packages:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -OptionalPackages CMake,LLVM,Bun
```

Dry run:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -WhatIf
```

## What `setup.ps1` Does

- installs the core packages with `winget`
- installs any selected optional packages
- copies `.clink` into `%LOCALAPPDATA%\clink`
- copies `.starship\config.toml` into `$HOME\.config\starship.toml`
- appends Starship and Zoxide initialization to your PowerShell profile if it is not already present

After the script finishes, restart PowerShell, Windows Terminal, and any open `cmd.exe` sessions.

## Verify the Setup

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
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

To include optional packages again:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -OptionalPackages CMake,LLVM,Bun
```

`winget install` will reuse existing packages and upgrade them when newer versions are available.

## Troubleshooting

- Starship does not appear in `cmd.exe`: confirm `%LOCALAPPDATA%\clink\startship.lua` exists and `starship.exe` is on `PATH`
- Starship does not appear in PowerShell: confirm your PowerShell profile includes the Starship init block added by `setup.ps1`
- `z` does not work: open a new shell after installing Zoxide so `PATH` is refreshed
- `zi` does not work interactively: confirm `fzf` is installed and available on `PATH`
- icons look wrong: install a Nerd Font and select it in Windows Terminal
- colors or prompt rendering look wrong: use Windows Terminal or a recent console host with UTF-8 and VT support

## Uninstall

Remove the deployed config, the PowerShell profile snippet, and the core packages:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

Also remove optional packages:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -RemoveOptionalPackages
```

Dry run:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -WhatIf
```

## License

See [LICENSE](LICENSE).
