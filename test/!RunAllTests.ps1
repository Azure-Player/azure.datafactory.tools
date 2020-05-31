Write-Host "Setting new location: $(system.defaultworkingdirectory)"
Set-Location "$(system.defaultworkingdirectory)"
Get-Location | Out-Host

# Add the module location to the value of the PSModulePath environment variable
$p = [Environment]::GetEnvironmentVariable("PSModulePath")
$p += ";$(system.defaultworkingdirectory)"
[Environment]::SetEnvironmentVariable("PSModulePath", $p)

Write-Host "Installing PS modules..."
Install-Module 'Az.DataFactory' -Force -MinimumVersion 1.8.0
Install-Module 'PSScriptAnalyzer' -Force
Install-Module 'Pester' -Force
Install-Module '$(system.defaultworkingdirectory)'
Import-Module 'Pester'
Import-Module 'PSScriptAnalyzer'
Import-Module 'Az.DataFactory'
Get-Module | Out-Host

$env:ADF_ExampleCode = "$(system.defaultworkingdirectory)\test\BigFactorySample2\"
Invoke-Pester -Script "$(system.defaultworkingdirectory)\test\*.Tests.ps1" -EnableExit -OutputFile "TEST-Results.xml" -OutputFormat NUnitXml
