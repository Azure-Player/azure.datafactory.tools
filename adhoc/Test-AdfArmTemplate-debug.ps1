Import-Module ".\azure.datafactory.tools.psd1" -Force
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'

$folder = 'd:\GitHub\mrpaulandrew\Azure-Data-Integration-Pipelines-Advanced-Design-and-Delivery\Code\DataFactory'
Export-AdfToArmTemplate -RootFolder $folder

Publish-AdfV2FromJson -RootFolder $folder -ResourceGroupName 'rg-devops' -DataFactoryName 'padf2022bits' -Location 'uksouth'

Test-AdfArmTemplate 'd:\GitHub\SQLPlayer\azure.datafactory.examples\adf-simpledeployment\ArmTemplate\ARMTemplateForFactory.json'

Get-AzContext

$adf = Import-AdfFromFolder -FactoryName 'abc' -RootFolder $folder
Get-AdfDocDiagram -adf $adf
