.\debug\~~Load-all-cmdlets-locally.ps1

$ErrorActionPreference = 'Stop'

$SubscriptionName = 'MVP'
Set-AzContext -Subscription $SubscriptionName

$ResourceGroupName = 'rg-devops-factory'
$Location = "NorthEurope"
$RootFolder = "X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2"
$DataFactoryName = (Split-Path -Path $RootFolder -Leaf) + '-17274af1'


$adf = Import-AdfFromFolder -FactoryName 'abc' -RootFolder $RootFolder
Update-PropertiesFromFile -adf $adf -stage 'X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\deployment\config-multiple.csv'
Update-PropertiesFromFile -adf $adf -stage 'X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\deployment\config-c100.csv'
Update-PropertiesFromFile -adf $adf -stage 'X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\deployment\config-c005-extra-action.csv'




Set-Location "X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools"



$script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
$script:ConfigFolder = Join-Path -Path $RootFolder -ChildPath "deployment"
$script:option = New-AdfPublishOption
$option.FailsWhenConfigItemNotFound = $true
$script:adf.PublishOptions = $option
Update-PropertiesFromFile -Adf $adf -stage ( Join-Path -Path $script:ConfigFolder -ChildPath "config-missing.csv" )





