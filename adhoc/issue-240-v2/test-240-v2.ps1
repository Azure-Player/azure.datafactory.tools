#Import-Module ".\azure.datafactory.tools.psd1" -Force
#Get-Module 
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'
$DebugPreference = 'Continue'

. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session

$path = (.\adhoc\Get-RootPath.ps1)
$adf = Import-AdfFromFolder -FactoryName 'my-factory-001' -RootFolder $path

# Do test
# Enable the relevant line based on the configuration being tested
Test-AdfCode -RootFolder $path -ConfigPath "$path\config.csv"
Test-AdfCode -RootFolder $path -ConfigPath "$path\config.json"

# Do real update
# Enable the relevant line based on the configuration being tested
Update-PropertiesFromFile -adf $adf -stage "$path\config.csv"
Update-PropertiesFromFile -adf $adf -stage "$path\config.json"
