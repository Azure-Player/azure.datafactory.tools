Write-Host "=== Check NPM Version..."
npm version
Write-Host "=== Check finished."

$RootFolder = "x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo\BigFactoryTest"
Set-Location "$RootFolder"
$AdfUtilitiesVersion = '0.1.6'

Write-Host "=== Preparing package.json file..."
$packageJson = "{
    ""scripts"": {
        ""build"": ""node node_modules/@microsoft/azure-data-factory-utilities/lib/index""
    },
    ""dependencies"": {
        ""@microsoft/azure-data-factory-utilities"": ""^$AdfUtilitiesVersion""
    }
}"
Set-Content -Path "$RootFolder\package.json" -Value $packageJson -Force



Write-Host "=== Installing NPM azure-data-factory-utilities..."
npm i @microsoft/azure-data-factory-utilities
Write-Host "=== Installation finished."

$VerbosePreference = 'Continue'
$AdfName = Split-Path -Path $RootFolder -Leaf
$AdfName
$SubscriptionId = 'ffff'
$ResourceGroup = 'fakeRG'

$AdfName = 'BigFactoryTest'
$SubscriptionId = '0278080f-e1af-4ee8-98b3-881a286350aa'
$ResourceGroup = 'rg-datafactory'

$adfAzurePath = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DataFactory/factories/$AdfName"

cls
npm run build export "$RootFolder" "$adfAzurePath"
#This works


# Scenario: Point to ADF that doesn't exist yet (new):
$AdfName = 'BigFactoryPROD'  #new environment!
$adfAzurePath = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DataFactory/factories/$AdfName"
npm run build export "$RootFolder" "$adfAzurePath"
# The above will fails!








# Deploy to live
Import-Module 'azure.datafactory.tools'
$AdfName = 'BigFactoryTest'
$opt = New-AdfPublishOption
$opt.DeployGlobalParams = $true
Publish-AdfV2FromJson -RootFolder $RootFolder -ResourceGroupName $ResourceGroup -DataFactoryName $AdfName

Remove-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroup -DataFactoryName $AdfName -Name 'copyBinaryColumnViaBlob'


