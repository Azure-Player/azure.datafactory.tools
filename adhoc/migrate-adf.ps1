#############################################################
###### ADF: BigFactorySample2 
#############################################################
#Get-Module -Name "Az.DataFactory"
Remove-Module azure.datafactory.tools -ErrorAction:Ignore
Get-Module azure.datafactory.tools
$ErrorActionPreference = 'Stop'

$SubscriptionName = 'MVP'
Set-AzContext -Subscription $SubscriptionName
Get-AzContext

$ResourceGroupName = 'rg-devops-factory'
$Location = "NorthEurope"
$SourceAdf = 'BigFactorySample2-17274af1'
$TargetAdf = 'BigFactorySample2-88888888'

$adf = Get-AdfFromService -FactoryName $SourceAdf -ResourceGroupName $ResourceGroupName


# Deploy entire ADF
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location"

