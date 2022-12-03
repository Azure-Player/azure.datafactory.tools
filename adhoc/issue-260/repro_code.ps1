# Import-Module ".\azure.datafactory.tools.psd1" -Force
#Get-Module 
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'
$DebugPreference = 'Continue'
Set-StrictMode -Version 3

. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session

$path = (.\adhoc\Get-RootPath.ps1)
#$RootFolder = Join-Path $path 'ADF-BIGroupFacts01-Dev'
$RootFolder = "$path\test\BigFactorySample2"
$RootFolder = Join-Path $path 'AzureADF'
$RootFolder = 'd:\GitAz\SQLPlayer\ADF-demo\SQLPlayerDemo'
$ConfigFolder = Join-Path $RootFolder 'deployment'

# Test
Test-AdfCode -RootFolder $RootFolder -ConfigPath $ConfigFolder



# Investigation
$adfName = Split-Path -Path "$RootFolder" -Leaf
$adf = Import-AdfFromFolder -FactoryName "$adfName" -RootFolder "$RootFolder" -ErrorAction "SilentlyContinue"

$adf.GlobalFactory.GlobalParameters

#--if ($adf.Factories.Count -gt 0 -and (Get-Member -InputObject $adf.Factories[0].Body -name "properties" -Membertype "Properties")) {
Get-Member -InputObject $adf.Factories[0].Body.properties.globalParameters -Membertype "NoteProperty" 
$adf.GlobalFactory.GlobalParameters

# StrictMode & function

function test-something {
    Write-Host "check-some"
    Set-StrictMode -Version 1
    $adf.Factories[0].Body.properties.globalParameters
}

Set-StrictMode -Version 3
test-something
Write-Host "root code:"
$gparams = $adf.Factories[0].Body.properties.globalParameters
if ($gparams) 
{
    Get-Member -InputObject $adf.Factories[0].Body.properties.globalParameters -Membertype "NoteProperty" 
    Get-Member -InputObject $adf.GlobalFactory.GlobalParameters -Membertype "NoteProperty" 
}

