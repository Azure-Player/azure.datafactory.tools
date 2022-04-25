
Get-AzDataFactoryV2Dataset -ResourceGroupName 'rg-datafactory' -DataFactoryName 'SQLPlayerDemo'

Set-AzContext 'MVP'

Install-Module 'azure.datafactory.tools' -Scope CurrentUser
Import-Module 'azure.datafactory.tools'

$VerbosePreference = 'Continue'
$DebugPreference = 'SilentlyContinue'
Get-AdfFromService -ResourceGroupName 'rg-datafactory' -FactoryName 'SQLPlayerDemo'


# Variables
$rg      = 'rg-datafactory'
$adfName = 'SQLPlayerDemo'

# Retrieve all datasets via API without parsing
$token = Get-AzAccessToken -ResourceUrl 'https://management.azure.com'
$authHeader = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $token.Token
}
$adf = Get-AzDataFactoryV2 -ResourceGroupName $rg -DataFactoryName $adfName
$adf
$url = "https://management.azure.com$($adf.DataFactoryId)/datasets?api-version=2018-06-01"
$url

# Retrieve datasets one by one via Az.DataFactory module
$ErrorActionPreference = 'Stop'
$r = Invoke-RestMethod -Method Get -Uri $url -Headers $authHeader -ContentType "application/json"
$dsArray = $r.Value
foreach ($ds in $dsArray) {
    Write-Host "Reading dataset: $($ds.name) ..."
    Get-AzDataFactoryV2Dataset -ResourceGroupName $rg -DataFactoryName $adfName -Name $ds.name
}


