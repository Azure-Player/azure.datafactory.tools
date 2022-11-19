#Import-Module ".\azure.datafactory.tools.psd1" -Force
#Get-Module 
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'
$DebugPreference = 'Continue'

. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session

$path = (.\adhoc\Get-RootPath.ps1)
$adf = Import-AdfFromFolder -FactoryName 'abc' -RootFolder $path

# Do test
Test-AdfCode -RootFolder $path -ConfigPath "$path\config.csv"

# Do real update (remove)
Update-PropertiesFromFile -adf $adf -stage "$path\config.csv"
