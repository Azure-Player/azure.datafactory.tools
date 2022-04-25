$SubscriptionName = 'MVP'
Set-AzContext -Subscription $SubscriptionName
#Get-AzContext
$ErrorActionPreference = 'Stop'
$DebugPreference = "SilentlyContinue"
$VerbosePreference = 'Continue'


Set-Location "X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\"
$modules = 'azure.datafactory.tools'
Remove-Module -Name $modules -ErrorAction:Ignore
Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module azure.datafactory.tools

$ResourceGroupName = 'rg-devops-factory'
$Location = "NorthEurope"
$RootFolder = "x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo - Copy\BigFactorySample2" 
$DataFactoryName = (Split-Path -Path $RootFolder -Leaf) + '-17274af1'
$DataFactoryName




# issue 37
$adf = Import-AdfFromFolder -FactoryName "$DataFactoryName" -RootFolder "$RootFolder"
$list = $adf.GetUnusedDatasets()
$list
$list.GetType()

$adf.DataSets

[System.Collections.ArrayList] $dataset_list = @{}
$adf.DataSets | ForEach-Object `
{
    $null = $dataset_list.Add("$($_.Type).$($_.Name)") 
}

foreach ($i in $adf.Pipelines.DependsOn + $adf.DataFlows.DependsOn)
{
    $i
}

# Collect all objects used by pipelines and dataflows
$list = $adf.Pipelines.DependsOn + $adf.DataFlows.DependsOn
# Filter list to datasets only
$used = $list | Where-Object { $_.StartsWith('dataset.', "CurrentCultureIgnoreCase") } | `
                ForEach-Object { $_.Substring(8).Insert(0, 'dataset.') } | `
                Select-Object -Unique
$used

$used | ForEach-Object { $dataset_list.Remove($_, "CurrentCultureIgnoreCase") }
$used

# Test when adf has just been created and is empty
$modules = 'azure.datafactory.tools'
Remove-Module -Name $modules -ErrorAction:Ignore
.\debug\~~Load-all-cmdlets-locally.ps1

$adf = New-Object -TypeName Adf
$adf.GetUnusedDatasets()

