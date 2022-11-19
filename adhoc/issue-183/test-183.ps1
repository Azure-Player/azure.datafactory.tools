#Import-Module ".\azure.datafactory.tools.psd1" -Force
#Get-Module 
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session

$path = (.\adhoc\Get-RootPath.ps1)
$path
$adf = Import-AdfFromFolder -FactoryName 'abc' -RootFolder $path
#Import-AdfObjects -Adf $adf -All $adf.Pipelines -RootFolder "$path" -SubFolder "pipeline"

#$DebugPreference = 'Continue'
Update-PropertiesFromFile -adf $adf -stage "$path\config.csv"

# Result:
# Cannot bind argument to parameter 'value' because it is an empty string.

$Env:kvURI = "NewValue"
Update-PropertiesFromFile -adf $adf -stage "$path\config.csv"


$DebugPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
