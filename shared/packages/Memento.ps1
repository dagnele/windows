# Custom package: Memento
# Installs Memento CLI from GitHub releases via the project's install script.

$mementoInstallUrl = 'https://raw.githubusercontent.com/dagnele/memento/main/install.ps1'
$mementoInstallPath = Join-Path $env:LOCALAPPDATA 'Memento'

function Install-Package {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    Write-Step 'Installing Memento'
    if ($PSCmdlet.ShouldProcess('Memento', 'Install via remote script')) {
        & ([scriptblock]::Create((Invoke-RestMethod $mementoInstallUrl)))
    }
}

function Uninstall-Package {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    Write-Step 'Removing Memento'
    if ((Test-Path $mementoInstallPath) -and $PSCmdlet.ShouldProcess($mementoInstallPath, 'Remove')) {
        Remove-Item -Recurse -Force $mementoInstallPath
        Write-Host "Removed $mementoInstallPath"
    }
}
