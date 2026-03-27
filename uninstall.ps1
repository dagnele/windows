#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$InstallProfile = @('Base'),
    [switch]$All
)

$ErrorActionPreference = 'Stop'

$validProfiles = @('Base', 'AI', 'Rust', 'Extra')

$profilePackages = @{
    Base  = @(
        @{ Name = 'ripgrep'; Id = 'BurntSushi.ripgrep.MSVC' },
        @{ Name = 'fzf'; Id = 'junegunn.fzf' },
        @{ Name = 'Zoxide'; Id = 'ajeetdsouza.zoxide' },
        @{ Name = 'Starship'; Id = 'Starship.Starship' },
        @{ Name = 'Clink'; Id = 'chrisant996.Clink' },
        @{ Name = 'Git'; Id = 'Git.Git' },
        @{ Name = 'PowerShell'; Id = 'Microsoft.PowerShell' },
        @{ Name = 'Obsidian'; Id = 'Obsidian.Obsidian' },
        @{ Name = 'Neovim'; Id = 'Neovim.Neovim' }
    )
    AI    = @(
        @{ Name = 'OpenCode'; Id = 'SST.OpenCodeDesktop' }
    )
    Rust  = @(
        @{ Name = 'LLVM'; Id = 'LLVM.LLVM' },
        @{ Name = 'CMake'; Id = 'Kitware.CMake' },
        @{ Name = 'Rustup'; Id = 'Rustlang.Rustup' }
    )
    Extra = @(
        @{ Name = 'Tailscale'; Id = 'Tailscale.Tailscale' },
        @{ Name = 'Doppler'; Id = 'Doppler.doppler' },
        @{ Name = 'Bun'; Id = 'Oven-sh.Bun' },
        @{ Name = 'GitHub CLI'; Id = 'GitHub.cli' }
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

if ($All) {
    $selectedProfiles = $validProfiles
} else {
    $selectedProfiles = Resolve-Profiles -ProfileNames $InstallProfile
}

$packages = Resolve-Packages -ProfileNames $selectedProfiles
$removingBase = $selectedProfiles -icontains 'Base'

if ($removingBase) {
    Write-Step 'Removing deployed config'
    foreach ($path in @($clinkProfilePath, $starshipConfigPath)) {
        if ((Test-Path $path) -and $PSCmdlet.ShouldProcess($path, 'Remove')) {
            Remove-Item -Recurse -Force $path
            Write-Host "Removed $path"
        }
    }

    $profileContent = if (Test-Path $PROFILE) { Get-Content -Path $PROFILE -Raw } else { '' }
    if ($profileContent.IndexOf($profileSnippet, [System.StringComparison]::Ordinal) -ge 0) {
        if ($PSCmdlet.ShouldProcess($PROFILE, 'Remove Starship and Zoxide profile setup')) {
            $updated = $profileContent.Replace($profileSnippet, '').Trim()
            if ([string]::IsNullOrWhiteSpace($updated)) {
                Set-Content -Path $PROFILE -Value ''
            } else {
                Set-Content -Path $PROFILE -Value ($updated + "`n")
            }
            Write-Host "Updated PowerShell profile: $PROFILE"
        }
    }
}

$pathEntries = @()
foreach ($name in $selectedProfiles) {
    if ($profilePathEntries.ContainsKey($name)) { $pathEntries += $profilePathEntries[$name] }
}
if ($pathEntries.Count -gt 0) {
    Write-Step 'Cleaning up PATH'
    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = $currentPath -split ';' | Where-Object { $_ -ne '' }
    $newEntries = $entries | Where-Object { $dir = $_; -not ($pathEntries | Where-Object { $_ -ieq $dir }) }
    $newPath = $newEntries -join ';'
    if ($newPath -ne $currentPath -and $PSCmdlet.ShouldProcess('User PATH', 'Remove profile entries')) {
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        foreach ($dir in $pathEntries) { Write-Host "Removed $dir from user PATH" }
    }
}

Write-Step "Uninstalling packages for profiles: $($selectedProfiles -join ', ')"
foreach ($package in $packages) {
    if ($PSCmdlet.ShouldProcess($package.Id, 'Uninstall package with winget')) {
        Write-Host "Uninstalling $($package.Name) [$($package.Id)]"
        winget uninstall --id $package.Id -e --accept-source-agreements
    }
}

Write-Step 'Done'
Write-Host 'Restart PowerShell, Windows Terminal, and any open cmd.exe sessions.' -ForegroundColor Green
