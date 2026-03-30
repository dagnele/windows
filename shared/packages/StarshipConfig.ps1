# Custom package: StarshipConfig
# Copies Starship configuration into $HOME/.config/starship.toml.

function Install-Package {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $source = Join-Path $global:scriptRoot '.starship' 'config.toml'
    $destination = Join-Path $HOME '.config' 'starship.toml'

    Write-Step 'Copying Starship config'
    if ($PSCmdlet.ShouldProcess($destination, 'Copy Starship config')) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
        Copy-Item -Path $source -Destination $destination -Force
        Write-Host "Copied .starship/config.toml -> $destination"
    }
}

function Uninstall-Package {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $destination = Join-Path $HOME '.config' 'starship.toml'

    Write-Step 'Removing Starship config'
    if ((Test-Path $destination) -and $PSCmdlet.ShouldProcess($destination, 'Remove')) {
        Remove-Item -Force $destination
        Write-Host "Removed $destination"
    }
}
