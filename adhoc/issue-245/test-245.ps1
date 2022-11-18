Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module 
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# & .\adhoc\~~Load-all-cmdlets-locally.ps1
. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session

$path = (.\adhoc\Get-RootPath.ps1)
$adf = Import-AdfFromFolder -FactoryName 'abc' -RootFolder $path
Import-AdfObjects -Adf $adf -All $adf.Pipelines -RootFolder "$path" -SubFolder "pipeline"

Update-PropertiesFromFile -adf $adf -stage '.\adhoc\issue-245\config.csv'
