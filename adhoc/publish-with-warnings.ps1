$SubscriptionName = 'MVP'
Set-AzContext -Subscription $SubscriptionName
#Get-AzContext
$ErrorActionPreference = 'Stop'

Set-Location "X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\"
$modules = 'azure.datafactory.tools'
Remove-Module -Name $modules -ErrorAction:Ignore
Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module azure.datafactory.tools

$ResourceGroupName = 'rg-devops-factory'
$Location = "NorthEurope"
$RootFolder = "x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo - Copy\BigFactorySample2" 
#$RootFolder = "X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2"
$DataFactoryName = (Split-Path -Path $RootFolder -Leaf) + '-17274af1'

# Deploy nothing
$opt = New-AdfPublishOption
$opt.Includes.Add("*.CADOutput1", "")
$opt.IgnoreLackOfReferencedObject = $true
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt

# Start deploying object: [dataset].[CADOutput1] (1 dependency/ies)
# Deploy-AdfObject : Referenced object [BlobSampleData] was not found.
# At C:\Users\kamil\Documents\WindowsPowerShell\Modules\azure.datafactory.tools\0.18.0\public\Publish-AdfV2FromJson.ps1:182 char:9
# +         Deploy-AdfObject -obj $_
# +         ~~~~~~~~~~~~~~~~~~~~~~~~
#     + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
#     + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Deploy-AdfObject

PublishOption.IgnoreLackOfReferencedObject


$RootFolder = "X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2"
$stage = 'X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\deployment\config-missing.csv'
# Deploy nothing
$opt = New-AdfPublishOption
$opt.Excludes.Add("*.*", "")
$opt.CreateNewInstance = $false
$opt.FailsWhenConfigItemNotFound = $false
$opt.FailsWhenPathNotFound = $false
$opt.StopStartTriggers = $false
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt -Stage $stage

Get-Module azure.datafactory.tools

