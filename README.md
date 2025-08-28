# Windows Terminal Setup

Opinionated setup for an enhanced Windows command-line environment using:
- Clink (better cmd.exe line editing, Lua extensions)
- Starship (fast, configurable cross-shell prompt)
- Zoxide (smarter directory jumping)

## Features
- Consistent, informative prompt via Starship
- Powerful history search, completions, and prompt filtering via Clink
- Lightning fast directory navigation with `z` (zoxide)
- Modular Lua customization (`.clink` folder)
- Easy, reproducible install using Chocolatey

## Prerequisites
- Windows 10/11
- [Chocolatey](https://chocolatey.org/install) installed and available in an elevated PowerShell

## Installation
Install core tools:
```powershell
choco install -y clink starship zoxide
```
(If `starship` package name differs, use `starship` or `starshiptheme` as available in Chocolatey repository.)

Optionally update:
```powershell
choco upgrade -y clink starship zoxide
```

## Directory Layout
Place the configuration directories in your user profile (clone or copy this repo then link/copy):
```
%USERPROFILE%\.clink\        # Clink Lua scripts (startship.lua, zoxide.lua, others)
%USERPROFILE%\.starship\      # Starship config dir
%USERPROFILE%\.starship\config.toml  # Starship main configuration
```
From this repository root (`windows.git`):
```
.clink/        # Lua integration scripts
    startship.lua
    zoxide.lua
.starship/
    config.toml
```

### Deploy (copy) configs
```powershell
# From cloned repo root
Copy-Item -Recurse -Force .clink $env:USERPROFILE
Copy-Item -Recurse -Force .starship $env:USERPROFILE
```
Or create junctions (keeps repo live-linked):
```powershell
New-Item -ItemType Junction -Path "$env:USERPROFILE\.clink" -Target "$PWD\.clink"
New-Item -ItemType Junction -Path "$env:USERPROFILE\.starship" -Target "$PWD\.starship"
```
(Delete existing directories first if needed.)

## Configuration Files
- `.clink/startship.lua`: Bridges Starship prompt into Clink/cmd.
- `.clink/zoxide.lua`: Adds `z` integration (initializes zoxide hook for directory tracking).
- `.starship/config.toml`: Starship prompt modules, symbols, styling.

After copying, restart any open cmd/Windows Terminal sessions.

## Usage
- Jump to frequently used directories: `z project`, `z src`, `z ..`.
- Show matches while jumping: `z -I keyword`.
- Refresh Starship after edit: restart shell or run: `refresh` (if alias defined) or just start a new session.
- View active Starship config path: `starship explain`.

## Customization
Edit `config.toml` to adjust prompt modules (battery, git status, node, python, etc.).
Add or modify Lua scripts in `.clink` to extend behavior (key bindings, filters, color rules).
Run `starship preset list` (if available) for preset ideas, then merge snippets into your `config.toml`.

## Troubleshooting
- Starship not showing: ensure `starship.exe` is on PATH and `startship.lua` (note spelling) is loaded by Clink. File name here is `startship.lua`; rename to `starship.lua` if you prefer consistency.
- Zoxide `z` command missing: ensure Chocolatey added zoxide to PATH; open a new terminal or run `refreshenv`.
- Unicode/Icons missing: install a Nerd Font and set it in Windows Terminal settings.
- Colors wrong: verify your terminal uses UTF-8 and VT processing (Windows Terminal or recent conhost).

## Updating
Pull latest repo changes, then recopy (or junction keeps it automatic). Update binaries via Chocolatey upgrade command above.

## Uninstall
```powershell
choco uninstall clink starship zoxide
Remove-Item -Recurse -Force $env:USERPROFILE\.clink
Remove-Item -Recurse -Force $env:USERPROFILE\.starship
```

## License
See [LICENSE](LICENSE).
