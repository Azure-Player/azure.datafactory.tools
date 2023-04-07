Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module 
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'
$DebugPreference = 'Continue'

# & .\adhoc\~~Load-all-cmdlets-locally.ps1
. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session

$path = (.\adhoc\Get-RootPath.ps1)
$configFile = Resolve-Path "$path\config.csv"
$adf = Import-AdfFromFolder -FactoryName 'abc' -RootFolder $path
Update-PropertiesFromFile -adf $adf -stage $configFile

# + Warning in AzureDevOps!
