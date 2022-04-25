#############################################################
###### ADF: BigFactorySample2 
#############################################################
Get-Module -Name "Az.DataFactory"
Remove-Module azure.datafactory.tools -ErrorAction:Ignore
Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module azure.datafactory.tools
$ErrorActionPreference = 'Stop'

$SubscriptionName = 'MVP'
Set-AzContext -Subscription $SubscriptionName
Get-AzContext

$ResourceGroupName = 'rg-devops-factory'
$Location = "NorthEurope"
$RootFolder = "x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo - Copy\BigFactorySample2" 
#$RootFolder = "X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2"
$DataFactoryName = (Split-Path -Path $RootFolder -Leaf) + '-17274af1'

# Deploy entire ADF
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location"

# Deploy nothing
$opt = New-AdfPublishOption
$opt.Excludes.Add("*.*", "")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt



# Deploy GP only when no GP exist
$opt = New-AdfPublishOption
$opt.Excludes.Add("*.*", "")
$opt.Includes.Add("fac*.*", "")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt



# Deploy entire ADF without IR-DEV2019-Link
$opt = New-AdfPublishOption
$opt.Excludes.Add("int*.SharedIR-DEV2019", "")
$opt.Excludes.Add("*.LS_SqlServer_DEV19_AW2017", "")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt
# Neverending loop:
# Start deploying object: [trigger].[TR_Dimension4] (2 dependency/ies)
# Start deploying object: [trigger].[TR_Dimension5] (4 dependency/ies)
# Start deploying object: [trigger].[TR_Dimension4] (2 dependency/ies)
# Start deploying object: [trigger].[TR_Dimension5] (4 dependency/ies)
$opt.Excludes.Add("*.TR_Dimension5", "")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt
# New-AzResource : BadRequest : The document creation or update failed because of invalid reference 'tr_dimension5'.





# Deploy only pipelines
$opt = New-AdfPublishOption
$opt.DeleteNotInSource = $false
$opt.Includes.Add("pipeline.*","")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt

$opt = New-AdfPublishOption
$opt.DeleteNotInSource = $false
$opt.Includes.Add("pipe*.Taxi*","")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt


# This should deploy badly
$opt = New-AdfPublishOption
$opt.DeleteNotInSource = $false
$opt.StopStartTriggers = $false
$opt.Includes.Add("pipe*.PL_StoredProc","")
$opt.Includes.Add("pipe*.PL_Wait_Dynamic","")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" `
     -Option $opt

# This should deploy well
$opt = New-AdfPublishOption
$opt.DeleteNotInSource = $true
$opt.StopStartTriggers = $true
#$opt.Includes.Add("linked*.*","")
$opt.Includes.Add("pipeline.*","")
#$opt.Includes.Add("dataflow.*","")
#$opt.Includes.Add("dataset.*","")
#$opt.Includes.Add("integr*.*","")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" `
     -Option $opt -Method "AzResource"

#Get-AzResource -Name "$DataFactoryName" | ft
$VerbosePreference = 'Continue'








# Deploy triggers only, not disabling them - should throw error - TODO: Add as Unit Test
$opt = New-AdfPublishOption
$opt.DeleteNotInSource = $false
$opt.StopStartTriggers = $false
$opt.Includes.Add("trigger.*","")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt

# Deploy triggers only, not disabling them, but only 1 enabled trigger in target will be deleted...
# -    T1 Disabled       Action: Drop
# T2   T2 Active
# -    T3 Disabled
$opt = New-AdfPublishOption
$opt.DeleteNotInSource = $true
$opt.StopStartTriggers = $false
$opt.Includes.Add("trigger.*","")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt
# Failed because wanted to update active trigger - new version should not requied it!

# Deploy triggers only, not disabling them, but only 1 enabled trigger in target will be deleted...
# -    T1 Disabled       Action: Drop
# T2   T2 Active        Action: Update
# -    T3 Disabled      Action: Drop
$opt = New-AdfPublishOption
$opt.DeleteNotInSource = $true
$opt.StopStartTriggers = $true 
$opt.Includes.Add("trigger.*","")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt

# Drop disabled trigger not switiching it off before
# -   T2 Active        Action: Update
$opt = New-AdfPublishOption
$opt.DeleteNotInSource = $true
$opt.StopStartTriggers = $false
$opt.Includes.Add("trigger.*","")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt
# !!! Strange behaviour: no warnings/error - Do not remove it - when Trigger is assigned to any pipeline



# Deploy the Pipeline assign to active trigger without switching the trigger off.   ok! PASS
$opt = New-AdfPublishOption
$opt.DeleteNotInSource = $false
$opt.StopStartTriggers = $false
$opt.Includes.Add("pipeline.PL_Wait5sec","")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt




# Deploy Disabled trigger to UAT and make it Enable (by config)
$opt = New-AdfPublishOption
$opt.StopStartTriggers = $true
$opt.DeleteNotInSource = $false
$opt.Includes.Add("trigger.TR_AlwaysDisabled11","")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Stage "UAT" -Option $opt

Set-AzDataFactoryV2Trigger -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Name 'TR_AlwaysDisabled' -DefinitionFile '.\test\BigFactorySample2\trigger\TR_AlwaysDisabled.json'
Set-AzDataFactoryV2Trigger -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Name 'TR_RunEveryDay' -DefinitionFile '.\test\BigFactorySample2\trigger\TR_RunEveryDay.json' -Force







$adf = Import-AdfFromFolder -FactoryName $DataFactoryName -RootFolder "$RootFolder"
Write-Host ($adf.Triggers -eq $null)

$adf.Triggers.Count





# Deploy only pipelines
$RootFolder = "X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2"
$opt = New-AdfPublishOption
$opt.DeleteNotInSource = $false
$opt.StopStartTriggers = $false
$opt.Excludes.Add("*.*","")
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" `
     -Location "$Location" -Option $opt `
     -Stage 'X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\deployment\config-issue49.csv'

