#############################################################
###### ADF: BigFactorySample2 
#############################################################
Get-Module -Name "Az.DataFactory" -ListAvailable
# 'C:\Users\kamil\Documents\WindowsPowerShell\Modules\Az.DataFactory\1.10.0'
Remove-Module azure.datafactory.tools -ErrorAction:Ignore
Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module azure.datafactory.tools
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

$SubscriptionName = 'MVP'
Set-AzContext -Subscription $SubscriptionName
Get-AzContext

$ResourceGroupName = 'rg-devops-factory'
$Location = "NorthEurope"
$RootFolder = "x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2"
$DataFactoryName = (Split-Path -Path $RootFolder -Leaf) + '-17274af1'

# Import test
$adf = Import-AdfFromFolder -FactoryName "$DataFactoryName" -RootFolder "$RootFolder"
$adf.Factories[0]
$adf.Factories[0].Body.properties
$adf.GlobalFactory

$fn = $adf.Pipelines[0].GetFolderName()
$null -eq $fn


# Deploy GP only
$opt = New-AdfPublishOption
#$opt.Excludes.Add("*.*", "")
$opt.Includes.Add("fact*.*", "")
$opt.DeployGlobalParams = $true
$opt.StopStartTriggers = $false
#$opt.DeployGlobalParams = $false
$adf = Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" `
     -Location "$Location" -Option $opt -Stage 'globalparam1'

Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt




$ResourceGroupName = 'rg-datafactory'
$Location = "NorthEurope"
$DataFactoryName = (Split-Path -Path $RootFolder -Leaf) 


$r = Get-AzResource `
            -ResourceType "Microsoft.DataFactory/factories" `
            -ResourceGroupName $ResourceGroupName `
            -Name "$DataFactoryName" `
            -ApiVersion "2018-06-01"
$r

$a = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name "$DataFactoryName"
$a.RepoConfiguration



$adf.GetObjectsByFolderName('ExternalError')
$adf.GetObjectsByFolderName('External*')
$adf.GetObjectsByFullName("dataset.taxi_*")

$ResourceGroupName = 'rg-datafactory'
$DataFactoryName = 'BigFactorySample2'
Stop-AdfTriggers -FactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName










# Deploy GP only
$opt = New-AdfPublishOption
$opt.Excludes.Add("*.*", "")
#$opt.Includes.Add("fact*.*", "")
$opt.DeployGlobalParams = $false
$opt.StopStartTriggers = $false
#$opt.DeployGlobalParams = $false
$adf = Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" `
     -Location "$Location" -Option $opt -Stage 'multiple'




# Save Test
$adf = Import-AdfFromFolder -FactoryName "$DataFactoryName" -RootFolder "$RootFolder"
$o = Get-AdfObjectByName -adf $adf -name 'PL_Wait5sec' -type 'pipeline'
$o.GetType()
Save-AdfObjectAsFile -obj $o

