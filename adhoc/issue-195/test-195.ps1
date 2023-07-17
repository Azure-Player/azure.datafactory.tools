Import-Module ".\azure.datafactory.tools.psd1" -Force
#Get-Module 

Get-AzContext
Select-AzSubscription -SubscriptionName 'MVP'


$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'
#$DebugPreference = 'Continue'

#. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session

$opt = New-AdfPublishOption
#$opt.Excludes.Add('*.*', '')
$opt.Includes.Add('link*.*', '')
$opt.Includes.Add('fac*.*', '')
$opt.IncrementalDeployment = $true
$ResourceGroupName = 'rg-devops-factory'
$DataFactoryName = "adf2-99443"
$RootFolder = "D:\GitHub\SQLPlayer\azure.datafactory.tools\test\adf2"
$Location = "UK South"

Import-Module ".\azure.datafactory.tools.psd1" -Force
$adf = Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"  -Location "$Location" -Option $opt
$adf


$res = Get-GlobalParam -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName

#-----------------
Select-AzSubscription -SubscriptionName 'Microsoft Azure Sponsorship'

$opt = New-AdfPublishOption
$opt.Excludes.Add('integr*.*', '')
$opt.Excludes.Add('link*.LS_SQLServer_DEV19*', '')
$opt.IncrementalDeployment = $true
$ResourceGroupName = 'rg-devops-factory'
$DataFactoryName = "BigFactorySample2-17274af2"
$RootFolder = "D:\GitHub\SQLPlayer\azure.datafactory.tools\test\BigFactorySample2"
$Location = "NorthEurope"

$adf = Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"  -Location "$Location" -Option $opt


# [Unnecessarily start & stop triggers]
$opt.IncrementalDeployment = $true
$opt.TriggerStopMethod = 'DeployableOnly'
#$opt.TriggerStartMethod = 'KeepPreviousState'
$adf = Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"  -Location "$Location" -Option $opt

