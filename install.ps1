#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$InstallProfile = @('Base')
)

$ErrorActionPreference = 'Stop'

$validProfiles = @('Base', 'AI', 'Rust', 'Extra')

$profilePackages = @{
    Base  = @(
        @{ Name = 'PowerShell'; Id = 'Microsoft.PowerShell' },
        @{ Name = 'Git'; Id = 'Git.Git' },
        @{ Name = 'Clink'; Id = 'chrisant996.Clink' },
        @{ Name = 'Starship'; Id = 'Starship.Starship' },
        @{ Name = 'Zoxide'; Id = 'ajeetdsouza.zoxide' },
        @{ Name = 'fzf'; Id = 'junegunn.fzf' },
        @{ Name = 'ripgrep'; Id = 'BurntSushi.ripgrep.MSVC' },
        @{ Name = 'Obsidian'; Id = 'Obsidian.Obsidian' },
        @{ Name = 'Neovim'; Id = 'Neovim.Neovim' }
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
}

$profilePathEntries = @{
    AI = @(
        (Join-Path $env:LOCALAPPDATA 'OpenCode')
    )
}

$profileSnippet = @'
Invoke-Expression (&"starship.exe" init powershell)

Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell | Out-String)
})
'@

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$clinkProfilePath = Join-Path $env:LOCALAPPDATA 'clink'
$starshipConfigPath = Join-Path $HOME '.config' 'starship.toml'

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Resolve-Profiles {
    param([string[]]$ProfileNames)

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

    if ($resolved -inotcontains 'Base') { $resolved = @('Base') + $resolved }
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

# --- main ---

if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is required but was not found on PATH.'
}

$selectedProfiles = Resolve-Profiles -ProfileNames $InstallProfile
$packages = Resolve-Packages -ProfileNames $selectedProfiles

Write-Step "Installing packages for profiles: $($selectedProfiles -join ', ')"
foreach ($package in $packages) {
    if ($PSCmdlet.ShouldProcess($package.Id, 'Install package with winget')) {
        Write-Host "Installing $($package.Name) [$($package.Id)]"
        winget install --id $package.Id -e --accept-package-agreements --accept-source-agreements
    }
}

Write-Step 'Copying Clink and Starship config'
if ($PSCmdlet.ShouldProcess($clinkProfilePath, 'Copy Clink config')) {
    New-Item -ItemType Directory -Force -Path $clinkProfilePath | Out-Null
    Copy-Item -Path (Join-Path $scriptRoot '.clink' '*') -Destination $clinkProfilePath -Recurse -Force
    Write-Host "Copied .clink -> $clinkProfilePath"
}
if ($PSCmdlet.ShouldProcess($starshipConfigPath, 'Copy Starship config')) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $starshipConfigPath) | Out-Null
    Copy-Item -Path (Join-Path $scriptRoot '.starship' 'config.toml') -Destination $starshipConfigPath -Force
    Write-Host "Copied .starship/config.toml -> $starshipConfigPath"
}

$pathEntries = @()
foreach ($name in $selectedProfiles) {
    if ($profilePathEntries.ContainsKey($name)) { $pathEntries += $profilePathEntries[$name] }
}
if ($pathEntries.Count -gt 0) {
    Write-Step 'Configuring PATH'
    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = $currentPath -split ';' | Where-Object { $_ -ne '' }
    foreach ($dir in $pathEntries) {
        if ($entries -icontains $dir) {
            Write-Host "PATH already contains $dir" -ForegroundColor Yellow
        } elseif ($PSCmdlet.ShouldProcess($dir, 'Add to user PATH')) {
            $entries += $dir
            Write-Host "Added $dir to user PATH"
        }
    }
    $newPath = $entries -join ';'
    if ($newPath -ne $currentPath -and $PSCmdlet.ShouldProcess('User PATH', 'Save updated PATH')) {
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        $env:Path = ($env:Path -split ';' | Where-Object { $_ -ne '' }) + $pathEntries -join ';'
    }
}

Write-Step 'Configuring PowerShell profile'
$profileContent = if (Test-Path $PROFILE) { Get-Content -Path $PROFILE -Raw } else { '' }
if ($profileContent -match [regex]::Escape('starship.exe') -or $profileContent -match [regex]::Escape('zoxide init --hook')) {
    Write-Host "PowerShell profile already contains Starship or Zoxide setup: $PROFILE" -ForegroundColor Yellow
} elseif ($PSCmdlet.ShouldProcess($PROFILE, 'Append Starship and Zoxide init')) {
    $profileDir = Split-Path -Parent $PROFILE
    if (!(Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
    $prefix = if ([string]::IsNullOrWhiteSpace($profileContent)) { '' } else { "`n`n" }
    Add-Content -Path $PROFILE -Value ($prefix + $profileSnippet)
    Write-Host "Updated PowerShell profile: $PROFILE"
}

Write-Step 'Done'
Write-Host 'Restart PowerShell, Windows Terminal, and any open cmd.exe sessions.' -ForegroundColor Green
