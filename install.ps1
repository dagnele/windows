[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$OptionalPackages = @()
)

$ErrorActionPreference = 'Stop'

$corePackages = @(
    @{ Name = 'Windows Terminal'; Id = 'Microsoft.WindowsTerminal' },
    @{ Name = 'PowerShell'; Id = 'Microsoft.PowerShell' },
    @{ Name = 'Git'; Id = 'Git.Git' },
    @{ Name = 'GitHub CLI'; Id = 'GitHub.cli' },
    @{ Name = 'Clink'; Id = 'chrisant996.Clink' },
    @{ Name = 'Starship'; Id = 'Starship.Starship' },
    @{ Name = 'Zoxide'; Id = 'ajeetdsouza.zoxide' },
    @{ Name = 'fzf'; Id = 'junegunn.fzf' },
    @{ Name = 'ripgrep'; Id = 'BurntSushi.ripgrep.MSVC' }
)

$optionalPackageMap = @{
    CMake     = @{ Name = 'CMake'; Id = 'Kitware.CMake' }
    LLVM      = @{ Name = 'LLVM'; Id = 'LLVM.LLVM' }
    Bun       = @{ Name = 'Bun'; Id = 'Oven-sh.Bun' }
    Rustup    = @{ Name = 'Rustup'; Id = 'Rustlang.Rustup' }
    Doppler   = @{ Name = 'Doppler'; Id = 'Doppler.doppler' }
    Tailscale = @{ Name = 'Tailscale'; Id = 'Tailscale.Tailscale' }
    OpenCode  = @{ Name = 'OpenCode'; Id = 'SST.OpenCodeDesktop' }
}

$clinkProfilePath = Join-Path $env:LOCALAPPDATA 'clink'
$starshipConfigDirectory = Join-Path $HOME '.config'
$starshipConfigPath = Join-Path $starshipConfigDirectory 'starship.toml'

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Package
    )

    if ($PSCmdlet.ShouldProcess($Package.Id, 'Install package with winget')) {
        Write-Host "Installing $($Package.Name) [$($Package.Id)]"
        winget install --id $Package.Id -e --accept-package-agreements --accept-source-agreements
    }
}

function Copy-RepoDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (!(Test-Path $Source)) {
        throw "Missing source directory: $Source"
    }

    if ($PSCmdlet.ShouldProcess($Destination, "Copy files from $Source")) {
        New-Item -ItemType Directory -Force -Path $Destination | Out-Null
        Copy-Item -Path (Join-Path $Source '*') -Destination $Destination -Recurse -Force
        Write-Host "Copied $Source -> $Destination"
    }
}

function Copy-RepoFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (!(Test-Path $Source)) {
        throw "Missing source file: $Source"
    }

    $destinationDirectory = Split-Path -Parent $Destination
    if ($PSCmdlet.ShouldProcess($Destination, "Copy file from $Source")) {
        New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null
        Copy-Item -Path $Source -Destination $Destination -Force
        Write-Host "Copied $Source -> $Destination"
    }
}

function Ensure-PowerShellProfileSetup {
    $profileSnippet = @'
Invoke-Expression (&"starship.exe" init powershell)

Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell | Out-String)
})
'@

    $profileDirectory = Split-Path -Parent $PROFILE
    if (!(Test-Path $profileDirectory)) {
        if ($PSCmdlet.ShouldProcess($profileDirectory, 'Create PowerShell profile directory')) {
            New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
        }
    }

    if (!(Test-Path $PROFILE)) {
        if ($PSCmdlet.ShouldProcess($PROFILE, 'Create PowerShell profile file')) {
            New-Item -ItemType File -Path $PROFILE -Force | Out-Null
        }
    }

    $existingProfile = if (Test-Path $PROFILE) { Get-Content -Path $PROFILE -Raw } else { '' }

    if ($existingProfile -match [regex]::Escape('starship.exe') -or $existingProfile -match [regex]::Escape('zoxide init --hook')) {
        Write-Host "PowerShell profile already contains Starship or Zoxide setup: $PROFILE" -ForegroundColor Yellow
        return
    }

    if ($PSCmdlet.ShouldProcess($PROFILE, 'Append Starship and Zoxide profile setup')) {
        $prefix = if ([string]::IsNullOrWhiteSpace($existingProfile)) { '' } else { [Environment]::NewLine + [Environment]::NewLine }
        Add-Content -Path $PROFILE -Value ($prefix + $profileSnippet)
        Write-Host "Updated PowerShell profile: $PROFILE"
    }
}

function Resolve-OptionalPackages {
    param(
        [string[]]$PackageNames
    )

    $resolvedPackages = @()

    if (-not $PackageNames -or $PackageNames.Count -eq 0) {
        return $resolvedPackages
    }

    foreach ($entry in $PackageNames) {
        foreach ($packageName in ($entry -split ',')) {
            $trimmedName = $packageName.Trim()
            if ([string]::IsNullOrWhiteSpace($trimmedName)) {
                continue
            }

            $match = $optionalPackageMap.GetEnumerator() | Where-Object { $_.Key -ieq $trimmedName } | Select-Object -First 1
            if (-not $match) {
                $validNames = ($optionalPackageMap.Keys | Sort-Object) -join ', '
                throw "Unknown optional package '$trimmedName'. Valid values: $validNames"
            }

            if ($resolvedPackages.Id -contains $match.Value.Id) {
                continue
            }

            $resolvedPackages += $match.Value
        }
    }

    return $resolvedPackages
}

if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is required but was not found on PATH.'
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Step 'Installing core packages'
foreach ($package in $corePackages) {
    Install-WingetPackage -Package $package
}

$selectedOptionalPackages = Resolve-OptionalPackages -PackageNames $OptionalPackages

if ($selectedOptionalPackages.Count -gt 0) {
    Write-Step 'Installing selected optional packages'
    foreach ($package in $selectedOptionalPackages) {
        Install-WingetPackage -Package $package
    }
}

Write-Step 'Copying Clink and Starship config'
Copy-RepoDirectory -Source (Join-Path $scriptRoot '.clink') -Destination $clinkProfilePath
Copy-RepoFile -Source (Join-Path $scriptRoot '.starship\config.toml') -Destination $starshipConfigPath

Write-Step 'Configuring PowerShell profile'
Ensure-PowerShellProfileSetup

Write-Step 'Done'
Write-Host 'Restart PowerShell, Windows Terminal, and any open cmd.exe sessions.' -ForegroundColor Green
