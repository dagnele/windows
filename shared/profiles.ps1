# Shared profile definitions, helpers, and config paths.
# Dot-source this file from install.ps1 and uninstall.ps1.
#
# Package types:
#   winget  - installed via winget install --id <Id>
#   custom  - installed via shared/packages/<Name>.ps1 (Install-Package / Uninstall-Package)

$validProfiles = @('Base', 'Editor', 'Browser', 'AI', 'Rust', 'BuildExtras', 'Bun', 'Python', 'Extra')

$profilePackages = @{
    Base  = @(
        @{ Name = 'Windows Terminal'; Id = 'Microsoft.WindowsTerminal'; Type = 'winget' },
        @{ Name = 'PowerToys'; Id = 'Microsoft.PowerToys'; Type = 'winget' },
        @{ Name = 'PowerShell'; Id = 'Microsoft.PowerShell'; Type = 'winget' },
        @{ Name = 'Git'; Id = 'Git.Git'; Type = 'winget' },
        @{ Name = 'Clink'; Id = 'chrisant996.Clink'; Type = 'winget' },
        @{ Name = 'Starship'; Id = 'Starship.Starship'; Type = 'winget' },
        @{ Name = 'Zoxide'; Id = 'ajeetdsouza.zoxide'; Type = 'winget' },
        @{ Name = 'fzf'; Id = 'junegunn.fzf'; Type = 'winget' },
        @{ Name = 'ripgrep'; Id = 'BurntSushi.ripgrep.MSVC'; Type = 'winget' },
        @{ Name = 'ClinkConfig'; Type = 'custom' },
        @{ Name = 'StarshipConfig'; Type = 'custom' },
        @{ Name = 'ShellProfile'; Type = 'custom' }
    )
    AI    = @(
        @{ Name = 'OpenCode'; Id = 'SST.OpenCodeDesktop'; Type = 'winget' },
        @{ Name = 'OpenCodeConfig'; Type = 'custom' },
        @{ Name = 'Memento'; Type = 'custom' }
    )
    Rust  = @(
        @{ Name = 'Rustup'; Id = 'Rustlang.Rustup'; Type = 'winget' }
    )
    BuildExtras = @(
        @{ Name = 'CMake'; Id = 'Kitware.CMake'; Type = 'winget' },
        @{ Name = 'LLVM'; Id = 'LLVM.LLVM'; Type = 'winget' }
    )
    Extra = @(
        @{ Name = 'GitHub CLI'; Id = 'GitHub.cli'; Type = 'winget' },
        @{ Name = 'Doppler'; Id = 'Doppler.doppler'; Type = 'winget' },
        @{ Name = 'Tailscale'; Id = 'Tailscale.Tailscale'; Type = 'winget' }
    )
    Bun   = @(
        @{ Name = 'Bun'; Id = 'Oven-sh.Bun'; Type = 'winget' }
    )
    Editor = @(
        @{ Name = 'Neovim'; Id = 'Neovim.Neovim'; Type = 'winget' },
        @{ Name = 'Obsidian'; Id = 'Obsidian.Obsidian'; Type = 'winget' },
        @{ Name = 'Oh My Posh'; Id = 'JanDeDobbeleer.OhMyPosh'; Type = 'winget' },
        @{ Name = 'Zig'; Id = 'zig.zig'; Type = 'winget' },
        @{ Name = 'WinLibs'; Id = 'BrechtSanders.WinLibs.POSIX.UCRT'; Type = 'winget' }
    )
    Browser = @(
        @{ Name = 'Zen Browser'; Id = 'Zen-Team.Zen-Browser'; Type = 'winget' }
    )
    Python = @(
        @{ Name = 'Python 3.12'; Id = 'Python.Python.3.12'; Type = 'winget' }
    )
}

$profilePathEntries = @{
    AI = @(
        (Join-Path $env:LOCALAPPDATA 'OpenCode'),
        (Join-Path $env:LOCALAPPDATA 'Memento')
    )
    Editor = @(
        (Join-Path $env:USERPROFILE '.cargo' 'bin')
    )
}

$packagesDir = Join-Path $PSScriptRoot 'packages'

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Resolve-Profiles {
    param(
        [string[]]$ProfileNames,
        [switch]$IncludeBase
    )

    $resolved = @()
    foreach ($entry in $ProfileNames) {
        foreach ($name in ($entry -split ',')) {
            $name = $name.Trim()
            if ([string]::IsNullOrWhiteSpace($name)) { continue }

            $match = $validProfiles | Where-Object { $_ -ieq $name } | Select-Object -First 1
            if (-not $match) {
                throw "Unknown profile '$name'. Valid profiles: $($validProfiles -join ', ')"
            }
            if ($resolved -inotcontains $match) { $resolved += $match }
        }
    }

    if ($IncludeBase -and $resolved -inotcontains 'Base') {
        $resolved = @('Base') + $resolved
    }
    return $resolved
}

function Resolve-Packages {
    param([string[]]$ProfileNames)

    $packages = @()
    foreach ($profileName in $ProfileNames) {
        foreach ($package in $profilePackages[$profileName]) {
            if ($package.Type -eq 'winget') {
                if ($packages.Id -notcontains $package.Id) { $packages += $package }
            } else {
                if ($packages.Name -notcontains $package.Name) { $packages += $package }
            }
        }
    }
    return $packages
}
