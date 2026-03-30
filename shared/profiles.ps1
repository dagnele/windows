# Shared profile definitions, helpers, and config paths.
# Dot-source this file from install.ps1 and uninstall.ps1.

$validProfiles = @('Base', 'Editor', 'Browser', 'AI', 'Rust', 'Python', 'Extra')

$profilePackages = @{
    Base  = @(
        @{ Name = 'Windows Terminal'; Id = 'Microsoft.WindowsTerminal' },
        @{ Name = 'PowerToys'; Id = 'Microsoft.PowerToys' },
        @{ Name = 'PowerShell'; Id = 'Microsoft.PowerShell' },
        @{ Name = 'Git'; Id = 'Git.Git' },
        @{ Name = 'Clink'; Id = 'chrisant996.Clink' },
        @{ Name = 'Starship'; Id = 'Starship.Starship' },
        @{ Name = 'Zoxide'; Id = 'ajeetdsouza.zoxide' },
        @{ Name = 'fzf'; Id = 'junegunn.fzf' },
        @{ Name = 'ripgrep'; Id = 'BurntSushi.ripgrep.MSVC' }
    )
    AI    = @(
        @{ Name = 'OpenCode'; Id = 'SST.OpenCodeDesktop' }
    )
    Rust  = @(
        @{ Name = 'Rustup'; Id = 'Rustlang.Rustup' },
        @{ Name = 'CMake'; Id = 'Kitware.CMake' },
        @{ Name = 'LLVM'; Id = 'LLVM.LLVM' }
    )
    Extra = @(
        @{ Name = 'GitHub CLI'; Id = 'GitHub.cli' },
        @{ Name = 'Bun'; Id = 'Oven-sh.Bun' },
        @{ Name = 'Doppler'; Id = 'Doppler.doppler' },
        @{ Name = 'Tailscale'; Id = 'Tailscale.Tailscale' }
    )
    Editor = @(
        @{ Name = 'Neovim'; Id = 'Neovim.Neovim' },
        @{ Name = 'Obsidian'; Id = 'Obsidian.Obsidian' },
        @{ Name = 'Oh My Posh'; Id = 'JanDeDobbeleer.OhMyPosh' },
        @{ Name = 'Zig'; Id = 'zig.zig' },
        @{ Name = 'WinLibs'; Id = 'BrechtSanders.WinLibs.POSIX.UCRT' }
    )
    Browser = @(
        @{ Name = 'Zen Browser'; Id = 'Zen-Team.Zen-Browser' }
    )
    Python = @(
        @{ Name = 'Python 3.12'; Id = 'Python.Python.3.12' }
    )
}

$profilePathEntries = @{
    AI = @(
        (Join-Path $env:LOCALAPPDATA 'OpenCode')
    )
    Editor = @(
        (Join-Path $env:USERPROFILE '.cargo' 'bin')
    )
}

$profileSnippet = @'
Invoke-Expression (&"starship.exe" init powershell)

Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell | Out-String)
})

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\zash.omp.json" | Invoke-Expression
}
'@

$clinkProfilePath = Join-Path $env:LOCALAPPDATA 'clink'
$starshipConfigPath = Join-Path $HOME '.config' 'starship.toml'
$opencodeConfigPath = Join-Path $HOME '.config' 'opencode'

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
            if ($packages.Id -notcontains $package.Id) { $packages += $package }
        }
    }
    return $packages
}
