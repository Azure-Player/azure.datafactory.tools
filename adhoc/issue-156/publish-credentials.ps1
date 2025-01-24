$SubscriptionName = 'Microsoft Azure Sponsorship'
if ($null -eq (Get-AzContext)) { Connect-AzAccount }
Select-AzSubscription -SubscriptionName $SubscriptionName
Get-AzContext

. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session

$currentPath = (.\adhoc\Get-RootPath.ps1)
$testAdf = 'BigFactorySample2'
$testPath = Split-Path $currentPath -Parent | Split-Path -Parent | Join-Path -ChildPath 'test' | Join-Path -ChildPath $testAdf
$testPath

$FileName = "$testPath\credential\credential1.json"
$body = (Get-Content -Path $FileName -Encoding "UTF8" | Out-String)
$json = $body | ConvertFrom-Json


#$resType = Get-AzureResourceType $obj.Type
$DataFactoryName = "$testAdf-7d6cdb5f"
$ResourceGroupName = 'rg-devops-factory'
$resType = 'Microsoft.DataFactory/factories/credentials'
$resName = "$DataFactoryName/credential1"

New-AzResource `
-ResourceType $resType `
-ResourceGroupName $ResourceGroupName `
-Name "$resName" `
-ApiVersion "2018-06-01" `
-Properties $json `
-IsFullObject -Force 

# ------------------------------------------------------------
Select-AzSubscription -SubscriptionName $SubscriptionName

# Delete credential
$adfi = Get-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName"
Remove-AdfObjectRestAPI -type_plural 'credentials' -name 'credential1' -adfInstance $adfi

Remove-AdfObjectRestAPI -type_plural 'credentials' -name 'credential13' -adfInstance $adfi -Force -ErrorVariable err -ErrorAction Stop | Out-Null


$err = ''
Remove-AdfObjectRestAPI -type_plural 'credentials' -name 'credential13' -adfInstance $adfi -ErrorVariable err -ErrorAction Stop | Out-Null
$err


# Test: Remove-AdfObjectIfNotInSource
$adfIns = Get-AdfFromService -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
$adf = Import-AdfFromFolder -FactoryName "$DataFactoryName" -RootFolder "$testPath"
Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $adfIns.Credentials[0] -adfInstance $adfIns

$adfIns.Credentials[0].Name


Import-Module ".\azure.datafactory.tools.psd1" -Force