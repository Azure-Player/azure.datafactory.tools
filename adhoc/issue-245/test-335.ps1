# ------------------------ test-335 --------------------

Import-Module ".\azure.datafactory.tools.psd1" -Force
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

$path = (.\adhoc\Get-RootPath.ps1)
Set-Location $path

$ResourceGroupName = 'rg-devops-factory'
$DataFactoryName = "BigFactorySample2-17274af2"
$Location = "NorthEurope"

Publish-AdfV2FromJson -RootFolder '.' -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Location $Location -Stage ".\config.csv" -DryRun
