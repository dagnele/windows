# Custom package: ShellProfile
# Appends Starship, Zoxide, and Oh My Posh initialization to the PowerShell profile.

$shellSnippet = @'
Invoke-Expression (&"starship.exe" init powershell)

Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell | Out-String)
})

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\zash.omp.json" | Invoke-Expression
}
'@

function Install-Package {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    Write-Step 'Configuring PowerShell profile'
    $profileContent = if (Test-Path $PROFILE) { Get-Content -Path $PROFILE -Raw } else { '' }
    if ($profileContent -match [regex]::Escape('starship.exe') -or $profileContent -match [regex]::Escape('zoxide init --hook')) {
        Write-Host "PowerShell profile already contains Starship or Zoxide setup: $PROFILE" -ForegroundColor Yellow
    } elseif ($PSCmdlet.ShouldProcess($PROFILE, 'Append Starship and Zoxide init')) {
        $profileDir = Split-Path -Parent $PROFILE
        if (!(Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
        $prefix = if ([string]::IsNullOrWhiteSpace($profileContent)) { '' } else { "`n`n" }
        Add-Content -Path $PROFILE -Value ($prefix + $shellSnippet)
        Write-Host "Updated PowerShell profile: $PROFILE"
    }
}

function Uninstall-Package {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    Write-Step 'Removing shell profile snippet'
    $profileContent = if (Test-Path $PROFILE) { Get-Content -Path $PROFILE -Raw } else { '' }
    if ($profileContent.IndexOf($shellSnippet, [System.StringComparison]::Ordinal) -ge 0) {
        if ($PSCmdlet.ShouldProcess($PROFILE, 'Remove Starship and Zoxide profile setup')) {
            $updated = $profileContent.Replace($shellSnippet, '').Trim()
            if ([string]::IsNullOrWhiteSpace($updated)) {
                Set-Content -Path $PROFILE -Value ''
            } else {
                Set-Content -Path $PROFILE -Value ($updated + "`n")
            }
            Write-Host "Updated PowerShell profile: $PROFILE"
        }
    }
}
