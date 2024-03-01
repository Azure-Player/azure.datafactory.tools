# Import-Module ".\azure.datafactory.tools.psd1" -Force
# Get-Module 
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

$script:ResourceGroupName = 'rg-devops-factory'
$script:Stage = 'UAT'
$c = Get-AzContext
$script:guid = $c.Subscription.Id.Substring(0,8)
$script:DataFactoryOrigName = 'BigFactorySample2'
$script:DataFactoryName = $script:DataFactoryOrigName + "-$guid"
$script:Location = "NorthEurope"
$RootFolder = '.\adhoc\issue-217'

$opt = New-AdfPublishOption
$opt.Excludes.Add("*.*", "")
$opt.Includes.Add("factory.*", "")
$opt.DeployGlobalParams = $true
$opt.StopStartTriggers = $false

# Without updating global params
Publish-AdfV2FromJson -RootFolder "$RootFolder" `
    -ResourceGroupName "$ResourceGroupName" `
    -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt 


