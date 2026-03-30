# Custom package: OpenCodeConfig
# Copies OpenCode configuration into $HOME/.config/opencode.

function Install-Package {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $source = Join-Path $global:scriptRoot '.opencode' '*'
    $destination = Join-Path $HOME '.config' 'opencode'

    Write-Step 'Copying OpenCode config'
    if ($PSCmdlet.ShouldProcess($destination, 'Copy OpenCode config')) {
        New-Item -ItemType Directory -Force -Path $destination | Out-Null
        Copy-Item -Path $source -Destination $destination -Recurse -Force
        Write-Host "Copied .opencode -> $destination"
    }
}

function Uninstall-Package {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $destination = Join-Path $HOME '.config' 'opencode'

    Write-Step 'Removing OpenCode config'
    if ((Test-Path $destination) -and $PSCmdlet.ShouldProcess($destination, 'Remove')) {
        Remove-Item -Recurse -Force $destination
        Write-Host "Removed $destination"
    }
}
