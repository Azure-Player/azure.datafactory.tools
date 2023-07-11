Import-Module ".\azure.datafactory.tools.psd1" -Force
#Get-Module 
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'
#$DebugPreference = 'Continue'

$path = (.\adhoc\Get-RootPath.ps1)
$RootFolder = Resolve-Path "$path\..\..\test\BigFactorySample2"

$ResourceGroupName = 'rg-devops-factory'
$guid = '5889b15h'
$DataFactoryOrigName = 'BigFactorySample2'
$DataFactoryName = $script:DataFactoryOrigName + "-$guid"

$opt = New-AdfPublishOption 
$opt.StopStartTriggers = $false
$opt.Includes.Add("factory.*", "")

Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" -Option $opt -Location 'uksouth' -Stage 'globalparam1'











# Publish GP
Set-GlobalParam -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -value "ZZZ"










# Clean up
Remove-AzDataFactoryV2 -Name $DataFactoryName -ResourceGroupName $ResourceGroupName
