Clear-Host
Import-Module azure.datafactory.tools 
Get-Module
# For update see: UpdateModules.ps1

#############################################################
###### ADF: adf-metadata-driven-proc
#############################################################
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'
$SubscriptionName = 'MVP'
Set-AzContext -Subscription $SubscriptionName
$ResourceGroupName = 'rg-pademo'
$DataFactoryName = 'adf-metadata-driven-proc'
$Location = "UKSouth"
$RootFolder = "x:\!WORK\GitHub\mrpaulandrew\ADF.procfwk\DataFactory"

Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"   `
   -Location $Location -Method "AzDataFactory"

$opt = New-AdfPublishOption
#$opt.Excludes.Add("pipeline.Wait *", "")
#$opt.Excludes.Add("pipeline.04-*", "")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"   `
   -Location $Location -Option $opt -Method "AzDataFactory"


$opt.DeleteNotInSource = $true
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"   `
   -Location $Location -Option $opt -Method "AzResource"


