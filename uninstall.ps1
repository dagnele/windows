#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$InstallProfile = @('Base'),
    [switch]$All
)

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptRoot 'shared' 'profiles.ps1')

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
