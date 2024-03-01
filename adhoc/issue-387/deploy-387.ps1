Import-Module ".\azure.datafactory.tools.psd1" -Force
#Get-Module 
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'
#$DebugPreference = 'Continue'

$path = (.\adhoc\Get-RootPath.ps1)
$RootFolder = Resolve-Path "$path"


$c = Get-AzContext
$guid = $c.Subscription.Id.Substring(0,8)
$ResourceGroupName = 'rg-devops-factory'
$DataFactoryOrigName = 'factory387'
$DataFactoryName = $script:DataFactoryOrigName + "-$guid"

$opt = New-AdfPublishOption 

Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" -Option $opt -Location 'uksouth'




                    





# Clean up
Remove-AzDataFactoryV2 -Name $DataFactoryName -ResourceGroupName $ResourceGroupName -Force

