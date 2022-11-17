#Import-Module ".\azure.datafactory.tools.psd1" -Force
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'SilentlyContinue'

. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session

$path = (.\adhoc\Get-RootPath.ps1)
$RootFolder = Resolve-Path "$path\..\..\test\BigFactorySample2"
$ConfigFolder = "$RootFolder\deployment"

$adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
$option = New-AdfPublishOption
$adf.PublishOptions = $option

$VerbosePreference = 'Continue'
Update-PropertiesFromFile -adf $script:adf -stage "$ConfigFolder\config-multiple.json"

