<#
.SYNOPSIS
Installs the PowerShell modules needed to develop and test azure.datafactory.tools locally.

.DESCRIPTION
Installs (for the current user, from PSGallery) every module that is missing or older than the minimum version:
- Az.Accounts, Az.Resources, Az.DataFactory: required by the module (RequiredModules in the manifest)
- Az.Storage: incremental deployment (deployment state in a storage account)
- Pester 6+: test framework (see CLAUDE.md)
- PSScriptAnalyzer: used by some tests
Also checks that Node.js and npm are available (Export-AdfToArmTemplate and its tests need them).
Modules already installed in a sufficient version are skipped, so the script can be run any time.

.PARAMETER Update
Installs the latest version of each module, even when a sufficient version is already installed.

.EXAMPLE
./tools/Install-DevPrerequisites.ps1

.EXAMPLE
./tools/Install-DevPrerequisites.ps1 -Update
#>
[CmdletBinding()]
param (
    [switch]$Update
)

$ErrorActionPreference = 'Stop'

$modules = [ordered]@{
    'Az.Accounts'      = '2.0.0'
    'Az.Resources'     = '6.5.0'
    'Az.DataFactory'   = '1.16.0'
    'Az.Storage'       = '5.0.0'
    'Pester'           = '6.0.0'
    'PSScriptAnalyzer' = '1.20.0'
}

Write-Host "PowerShell $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"

# Windows PowerShell 5.1 needs TLS 1.2 and the NuGet provider to install from PSGallery
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    if (-not (Get-PackageProvider -ListAvailable | Where-Object Name -eq 'NuGet')) {
        Write-Host "Installing NuGet package provider..."
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
    }
}

foreach ($name in $modules.Keys) {
    $minVersion = [version] $modules[$name]
    $installed = Get-Module -Name $name -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    if ($installed -and $installed.Version -ge $minVersion -and -not $Update) {
        Write-Host "OK        $name $($installed.Version)"
        continue
    }
    Write-Host "Installing $name (minimum $minVersion)..."
    $params = @{
        Name           = $name
        MinimumVersion = $minVersion
        Scope          = 'CurrentUser'
        Repository     = 'PSGallery'
        AllowClobber   = $true
        Force          = $true
    }
    # Pester 6 is signed by a different publisher than the built-in Pester 3.4.0
    if ($name -eq 'Pester') { $params.SkipPublisherCheck = $true }
    Install-Module @params
    $installed = Get-Module -Name $name -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    Write-Host "Installed $name $($installed.Version)"
}

$npm = if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') { 'npm.cmd' } else { 'npm' }
if ((Get-Command 'node' -ErrorAction SilentlyContinue) -and (Get-Command $npm -ErrorAction SilentlyContinue)) {
    Write-Host "OK        Node.js $(& node --version), npm $(& $npm --version)"
} else {
    Write-Warning "Node.js/npm not found. Export-AdfToArmTemplate and its tests need them: https://nodejs.org/"
}

Write-Host ""
Write-Host "Done. Run tests in a clean process, e.g.:"
Write-Host "  pwsh -NoProfile -Command `"Import-Module Pester -MinimumVersion 6.0; Import-Module ./azure.datafactory.tools.psd1; Invoke-Pester -Path ./test/Stop-Trigger.Tests.ps1 -Output Detailed`""
