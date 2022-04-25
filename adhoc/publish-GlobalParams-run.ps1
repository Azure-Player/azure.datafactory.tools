$ErrorActionPreference = 'Stop'

$ResourceGroupName = 'rg-devops-factory'
$Stage = 'UAT'
$DataFactoryName = "SQLPlayerDemo-$Stage"
$globalParametersFilePath = 'x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo-adf_publish\SQLPlayerDemo\globalParameters\SQLPlayerDemo_GlobalParameters.json'

.\debug\publish-GlobalParams.ps1 -globalParametersFilePath $globalParametersFilePath `
    -resourceGroupName $ResourceGroupName -dataFactoryName $DataFactoryName
