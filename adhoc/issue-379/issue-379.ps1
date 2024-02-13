Import-Module ".\azure.datafactory.tools.psd1" -Force
#Get-Module 
$ErrorActionPreference = 'Continue'
$VerbosePreference = 'Continue'
#$DebugPreference = 'Continue'

$path = (.\adhoc\Get-RootPath.ps1)
$RootFolder = Resolve-Path "$path\..\..\test\BigFactorySample2"

$ResourceGroupName = 'rg-devops-factory'
$guid = 'fe49b15c'
$DataFactoryOrigName = 'BigFactorySample2'
$DataFactoryName = $script:DataFactoryOrigName + "-$guid"

$opt = New-AdfPublishOption 
$opt.StopStartTriggers = $false
$opt.CreateNewInstance = $true
$opt.Includes.Add("factory.*", "")

Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" -Option $opt -Location 'uksouth'








# Clean up
Remove-AzDataFactoryV2 -Name $DataFactoryName -ResourceGroupName $ResourceGroupName -Force
