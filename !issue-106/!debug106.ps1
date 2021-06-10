Remove-Module 'azure.datafactory.tools'
Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module 'azure.datafactory.tools'
$VerbosePreference =   'Continue'

$ResourceGroupName = 'rg-devops-factory'
$Location = "NorthEurope"
$DataFactoryName = 'adf-issue-106'
$RootFolder = Join-Path (get-Location) '!issue-106\adf1'

$adf = Import-AdfFromFolder -FactoryName $DataFactoryName -RootFolder $RootFolder
$adf.ResourceGroupName = $ResourceGroupName
$adf.Region = $Location


$o = New-AdfPublishOption
$o.StopStartTriggers = $false
Publish-AdfV2FromJson -RootFolder $RootFolder -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -Option $o -Location $Location

# Step 2 & 3
$RootFolder = Join-Path (get-Location) '!issue-106\adf2'
$adf = Import-AdfFromFolder -FactoryName $DataFactoryName -RootFolder $RootFolder
$adf.ResourceGroupName = $ResourceGroupName
$adf.Region = $Location


$o = New-AdfPublishOption
$o.StopStartTriggers = $false
$o.DeleteNotInSource = $true
Publish-AdfV2FromJson -RootFolder $RootFolder -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -Option $o -Location $Location




# Drop ADF
Remove-AzDataFactoryV2 -Name $DataFactoryName -ResourceGroupName $ResourceGroupName -force
