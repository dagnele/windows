#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$InstallProfile = @('Base')
)

$ErrorActionPreference = 'Stop'

$global:scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $global:scriptRoot 'shared' 'profiles.ps1')

# --- main ---

if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is required but was not found on PATH.'
}

$selectedProfiles = Resolve-Profiles -ProfileNames $InstallProfile -IncludeBase
$packages = Resolve-Packages -ProfileNames $selectedProfiles

Write-Step "Installing packages for profiles: $($selectedProfiles -join ', ')"
foreach ($package in $packages) {
    if ($package.Type -eq 'custom') {
        $scriptPath = Join-Path $packagesDir "$($package.Name).ps1"
        . $scriptPath
        Install-Package -WhatIf:$WhatIfPreference
    } else {
        if ($PSCmdlet.ShouldProcess($package.Id, 'Install package with winget')) {
            Write-Host "Installing $($package.Name) [$($package.Id)]"
            winget install --id $package.Id -e --accept-package-agreements --accept-source-agreements
        }
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

Write-Step 'Done'
Write-Host 'Restart PowerShell, Windows Terminal, and any open cmd.exe sessions.' -ForegroundColor Green
