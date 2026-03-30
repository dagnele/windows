# Custom package: ClinkConfig
# Copies Clink configuration files into %LOCALAPPDATA%\clink.

function Install-Package {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $source = Join-Path $global:scriptRoot '.clink' '*'
    $destination = Join-Path $env:LOCALAPPDATA 'clink'

    Write-Step 'Copying Clink config'
    if ($PSCmdlet.ShouldProcess($destination, 'Copy Clink config')) {
        New-Item -ItemType Directory -Force -Path $destination | Out-Null
        Copy-Item -Path $source -Destination $destination -Recurse -Force
        Write-Host "Copied .clink -> $destination"
    }
}

function Uninstall-Package {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $destination = Join-Path $env:LOCALAPPDATA 'clink'

    Write-Step 'Removing Clink config'
    if ((Test-Path $destination) -and $PSCmdlet.ShouldProcess($destination, 'Remove')) {
        Remove-Item -Recurse -Force $destination
        Write-Host "Removed $destination"
    }
}
