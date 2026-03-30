#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$InstallProfile = @('Base'),
    [switch]$All
)

$ErrorActionPreference = 'Stop'

$global:scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $global:scriptRoot 'shared' 'profiles.ps1')

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
    if ($package.Type -eq 'custom') {
        $scriptPath = Join-Path $packagesDir "$($package.Name).ps1"
        . $scriptPath
        Uninstall-Package -WhatIf:$WhatIfPreference
    } else {
        if ($PSCmdlet.ShouldProcess($package.Id, 'Uninstall package with winget')) {
            Write-Host "Uninstalling $($package.Name) [$($package.Id)]"
            winget uninstall --id $package.Id -e --accept-source-agreements
        }
    }
}

Write-Step 'Done'
Write-Host 'Restart PowerShell, Windows Terminal, and any open cmd.exe sessions.' -ForegroundColor Green
