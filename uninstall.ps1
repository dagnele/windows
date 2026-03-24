[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$RemoveOptionalPackages
)

$ErrorActionPreference = 'Stop'

$corePackages = @(
    @{ Name = 'ripgrep'; Id = 'BurntSushi.ripgrep.MSVC' },
    @{ Name = 'fzf'; Id = 'junegunn.fzf' },
    @{ Name = 'Zoxide'; Id = 'ajeetdsouza.zoxide' },
    @{ Name = 'Starship'; Id = 'Starship.Starship' },
    @{ Name = 'Clink'; Id = 'chrisant996.Clink' },
    @{ Name = 'OpenCode'; Id = 'SST.OpenCodeDesktop' },
    @{ Name = 'GitHub CLI'; Id = 'GitHub.cli' },
    @{ Name = 'Git'; Id = 'Git.Git' },
    @{ Name = 'PowerShell'; Id = 'Microsoft.PowerShell' },
    @{ Name = 'Windows Terminal'; Id = 'Microsoft.WindowsTerminal' }
)

$optionalPackages = @(
    @{ Name = 'CMake'; Id = 'Kitware.CMake' },
    @{ Name = 'LLVM'; Id = 'LLVM.LLVM' },
    @{ Name = 'Bun'; Id = 'Oven-sh.Bun' },
    @{ Name = 'Rustup'; Id = 'Rustlang.Rustup' },
    @{ Name = 'Doppler'; Id = 'Doppler.doppler' },
    @{ Name = 'Tailscale'; Id = 'Tailscale.Tailscale' }
)

$clinkProfilePath = Join-Path $env:LOCALAPPDATA 'clink'
$starshipConfigPath = Join-Path (Join-Path $HOME '.config') 'starship.toml'

$profileSnippet = @'
Invoke-Expression (&"starship.exe" init powershell)

Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell | Out-String)
})
'@

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Uninstall-WingetPackage {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Package
    )

    if ($PSCmdlet.ShouldProcess($Package.Id, 'Uninstall package with winget')) {
        Write-Host "Uninstalling $($Package.Name) [$($Package.Id)]"
        winget uninstall --id $Package.Id -e --accept-source-agreements
    }
}

function Remove-PathIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathToRemove
    )

    if (!(Test-Path $PathToRemove)) {
        return
    }

    if ($PSCmdlet.ShouldProcess($PathToRemove, 'Remove deployed file or directory')) {
        Remove-Item -Recurse -Force $PathToRemove
        Write-Host "Removed $PathToRemove"
    }
}

function Remove-ProfileSnippet {
    if (!(Test-Path $PROFILE)) {
        return
    }

    $profileContent = Get-Content -Path $PROFILE -Raw
    if ($profileContent.IndexOf($profileSnippet, [System.StringComparison]::Ordinal) -lt 0) {
        Write-Host "PowerShell profile does not contain the setup snippet: $PROFILE" -ForegroundColor Yellow
        return
    }

    $updatedContent = $profileContent.Replace($profileSnippet, '').Trim()
    if ($PSCmdlet.ShouldProcess($PROFILE, 'Remove Starship and Zoxide profile setup')) {
        if ([string]::IsNullOrWhiteSpace($updatedContent)) {
            Set-Content -Path $PROFILE -Value ''
        } else {
            Set-Content -Path $PROFILE -Value ($updatedContent + [Environment]::NewLine)
        }

        Write-Host "Updated PowerShell profile: $PROFILE"
    }
}

if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is required but was not found on PATH.'
}

Write-Step 'Removing deployed config'
Remove-PathIfExists -PathToRemove $clinkProfilePath
Remove-PathIfExists -PathToRemove $starshipConfigPath
Remove-ProfileSnippet

Write-Step 'Uninstalling core packages'
foreach ($package in $corePackages) {
    Uninstall-WingetPackage -Package $package
}

if ($RemoveOptionalPackages) {
    Write-Step 'Uninstalling optional packages'
    foreach ($package in $optionalPackages) {
        Uninstall-WingetPackage -Package $package
    }
}

Write-Step 'Done'
Write-Host 'Restart PowerShell, Windows Terminal, and any open cmd.exe sessions.' -ForegroundColor Green
