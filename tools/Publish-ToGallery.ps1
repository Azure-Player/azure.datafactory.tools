[CmdletBinding()]
param (
    [switch]$IsPreview,

    [Parameter(Mandatory)]
    [string]$NuGetApiKey
)

$modulePath = Resolve-Path (Join-Path $PSScriptRoot '..')
$manifestPath = Join-Path $modulePath 'azure.datafactory.tools.psd1'

if ($IsPreview) {
    Write-Host "Tagging module as prerelease (preview)..."
    Update-ModuleManifest -Path $manifestPath -Prerelease 'preview'
}

Write-Host "Publishing module from: $modulePath"
Publish-Module -Path $modulePath -NuGetApiKey $NuGetApiKey -Verbose
