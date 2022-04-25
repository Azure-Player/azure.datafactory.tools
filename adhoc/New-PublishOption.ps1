
# $options = New-Object -TypeName AdfPublishOption
# $options.AddRule('pipeline.p1', 'Include')
# $options.AddRule('p2', 'Include')
# $options.AddRules('Include', @('p3','p4') )

# $options.Rules


"p1" -like "p1"
"p1" -like "p*"
"wait123" -like "wait*"
"wait123" -like "wait?"
"wait123" -like "wait???"
"Await123" -like "?wait???"
"[linkedService].[abc]" -like "linkedService.*"
"linkedService.abc" -like "[l]inkedService.*"
"ainkedService.abc" -like "[la]inkedService.*"



# Debug OFF
$VerbosePreference = 'SilentlyContinue'
$DebugPreference = "Continue"
$DebugPreference = "SilentlyContinue"
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'
Get-Module -Name "Az.DataFactory"

#############################################################
###### ADF: MigrateBigTable 
#############################################################
Get-Module -Name "Az.DataFactory"
Remove-Module azure.datafactory.tools
Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module azure.datafactory.tools

$SubscriptionName = 'MVP'
Set-AzContext -Subscription $SubscriptionName

$ResourceGroupName = 'rg-devops-factory'
$Stage = 'UAT'
$DataFactoryName = "SQLPlayerDemo-$Stage"
$RootFolder = "x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo\SQLPlayerDemo\"
$Location = "NorthEurope"

$adfSource = Import-AdfFromFolder -FactoryName "$DataFactoryName" -RootFolder "$RootFolder"
$adf = $adfSource

#$opt = New-Object -TypeName AdfPublishOption
$opt = New-AdfPublishOption
$opt.Includes.Add("SCD-Type1", "")
#$opt.Includes.Add("PL*", "")
$opt.DeleteNotInSource = $false
$opt

$opt = New-AdfPublishOption
$opt.Excludes.Add("linkedService.*", "")
$opt.Excludes.Add("integrationruntime.*", "")
$opt.Excludes.Add("trigger.*", "")
$opt.DeleteNotInSource = $false
$opt.Includes.Add("pipeline.Copy*", "")
$opt

$opt = New-AdfPublishOption
$opt.Excludes.Add("*", "")

$opt = New-AdfPublishOption
$opt.Includes.Add("*", "")
$opt.StopStartTriggers = $false

ApplyExclusionOptions -adf $adf -option $opt

# Adding multiple objects to 'include'



Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" `
    -Stage "UAT" `
    -Location "$Location" `
    -Option $opt



