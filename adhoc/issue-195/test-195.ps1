Import-Module ".\azure.datafactory.tools.psd1" -Force
#Get-Module 

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'
#$DebugPreference = 'Continue'

#. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session

$opt = New-AdfPublishOption
#$opt.Excludes.Add('*.*', '')
#$opt.Includes.Add('fac*.*', '')
$opt.IncrementalDeployment = $true
$ResourceGroupName = 'rg-devops-factory'
$DataFactoryName = "adf2-99443"
$RootFolder = "D:\GitHub\SQLPlayer\azure.datafactory.tools\test\adf2"
$Location = "UK South"

Import-Module ".\azure.datafactory.tools.psd1" -Force
$adf = Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"  -Location "$Location" -Option $opt
$adf


$res = Get-GlobalParam -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName

