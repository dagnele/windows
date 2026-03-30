#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$InstallProfile = @('Base')
)

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptRoot 'shared' 'profiles.ps1')

# --- main ---

if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is required but was not found on PATH.'
}

$selectedProfiles = Resolve-Profiles -ProfileNames $InstallProfile -IncludeBase
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
if ($selectedProfiles -icontains 'AI') {
    Write-Step 'Copying OpenCode config'
    if ($PSCmdlet.ShouldProcess($opencodeConfigPath, 'Copy OpenCode config')) {
        New-Item -ItemType Directory -Force -Path $opencodeConfigPath | Out-Null
        Copy-Item -Path (Join-Path $scriptRoot '.opencode' '*') -Destination $opencodeConfigPath -Recurse -Force
        Write-Host "Copied .opencode -> $opencodeConfigPath"
    }
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
