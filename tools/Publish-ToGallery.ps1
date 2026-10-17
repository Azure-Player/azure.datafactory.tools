[CmdletBinding()]
param (
    [switch]$IsPreview,

    [Parameter(Mandatory)]
    [string]$NuGetApiKey
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$moduleName = 'azure.datafactory.tools'

# Stage only the module files: Publish-Module packs the whole folder it is given,
# so publishing the repo root would ship tests, docs, node_modules, etc.
# The staging folder must be named after the module.
$stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) "adf-publish-$([guid]::NewGuid())"
$modulePath = Join-Path $stagingRoot $moduleName
New-Item -ItemType Directory -Path $modulePath | Out-Null

try {
    Copy-Item -Path (Join-Path $repoRoot '*.ps[dm]1') -Destination $modulePath
    Copy-Item -Path (Join-Path $repoRoot 'public') -Destination $modulePath -Recurse
    Copy-Item -Path (Join-Path $repoRoot 'private') -Destination $modulePath -Recurse

    $manifestPath = Join-Path $modulePath "$moduleName.psd1"
    if ($IsPreview) {
        Write-Host "Tagging module as prerelease (preview)..."
        Update-ModuleManifest -Path $manifestPath -Prerelease 'preview'
    }

    Write-Host "Files to publish:"
    Get-ChildItem -Path $modulePath -Recurse -File | ForEach-Object { Write-Host "  $($_.FullName.Substring($modulePath.Length + 1))" }

    Write-Host "Publishing module from: $modulePath"
    Publish-Module -Path $modulePath -NuGetApiKey $NuGetApiKey -Verbose
}
finally {
    Remove-Item -Path $stagingRoot -Recurse -Force -ErrorAction SilentlyContinue
}
