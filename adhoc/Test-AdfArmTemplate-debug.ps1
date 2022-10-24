Import-Module ".\azure.datafactory.tools.psd1" -Force
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'

$folder = 'X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\adf1'
Export-AdfToArmTemplate -RootFolder $folder

Publish-AdfV2FromJson -RootFolder $folder -ResourceGroupName 'rg-devops' -DataFactoryName 'padf2022bits' -Location 'uksouth'

Test-AdfArmTemplate 'd:\GitHub\SQLPlayer\azure.datafactory.examples\adf-simpledeployment\ArmTemplate\ARMTemplateForFactory.json'
$r = Test-AdfArmTemplate 'D:\azure.datafactory.tools-Export.Test\test\adf-simpledeployment-dev\armtemplate\ARMTemplateForFactory.json'
$r

Get-AzContext

$adf = Import-AdfFromFolder -FactoryName 'abc' -RootFolder $folder
$doc = Get-AdfDocDiagram -adf $adf
$doc | Set-Content 'diagram.md'
$doc
