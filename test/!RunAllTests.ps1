Param(
    [Parameter(Mandatory)]
    [string]$folder
)

Write-Host "Setting new location: $folder"
Set-Location "$folder"
Get-Location | Out-Host

# Add the module location to the value of the PSModulePath environment variable
#$p = [Environment]::GetEnvironmentVariable("PSModulePath")
#$p += ";$folder"
#[Environment]::SetEnvironmentVariable("PSModulePath", $p)

Write-Host "Installing PS modules..."
Install-Module 'Az.DataFactory' -Force -MinimumVersion 1.8.0
Install-Module 'PSScriptAnalyzer' -Force
Install-Module 'Pester' -Force -MinimumVersion 5.0.1
Import-Module 'Pester'
Import-Module 'PSScriptAnalyzer'
Import-Module 'Az.DataFactory'
Import-Module "$folder\azure.datafactory.tools.psd1"
Get-Module | Out-Host

$env:ADF_ExampleCode = "$folder\test\BigFactorySample2\"
Invoke-Pester -Script "$folder\test\*.Tests.ps1" -EnableExit -OutputFile "TEST-Results.xml" -OutputFormat NUnitXml
