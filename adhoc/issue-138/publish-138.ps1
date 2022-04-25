
Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module 
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

$DataFactoryName = 'BigFactorySample3'
$RootFolder = '.\test\BigFactorySample2'
$ResourceGroupName = 'rg-datafactory'
$Location = "NorthEurope"
#Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" 

Import-Module ".\azure.datafactory.tools.psd1" -Force
#Set-FactoryV2 -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Location $Location -PublicNetworkAccess 'Disabled'


$factoryFile = '.\test\BigFactorySample2\factory\BigFactorySample2.json'
New-AzResource `
    -ResourceType "Microsoft.DataFactory/factories" `
    -ResourceGroupName $ResourceGroupName `
    -Name $DataFactoryName `
    -ApiVersion "2018-06-01" `
    -Properties $factoryFile -Location $Location -Force

# don't deploy GPs & Network access !!! -> Only ARM!

Get-AzContext
Select-AzSubscription 'MVP'

Update-Module 'Az.DataFactory'
Remove-Module 'Az.DataFactory' -Force
Import-Module 'Az.DataFactory'
Get-Module ## 1.16.5
