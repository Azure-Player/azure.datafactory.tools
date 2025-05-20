Select-AzSubscription -SubscriptionName 'Microsoft Azure Sponsorship'

$testAdf = 'BigFactorySample2'
$DataFactoryName = "$testAdf-17274af2"
$ResourceGroupName = 'rg-devops-factory'
$adf = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
$adf

# Retrieve all credentials via API without parsing
try {
    # First attempt with -AsPlainText parameter (newer Az modules)
    $token = Get-AzAccessToken -ResourceUrl 'https://management.azure.com' -AsPlainText -ErrorAction Stop
} catch {
    # Fallback for older Az modules that don't support -AsPlainText
    $token = Get-AzAccessToken -ResourceUrl 'https://management.azure.com'
}
$authHeader = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $token.Token
}
$url = "https://management.azure.com$($adf.DataFactoryId)/credentials?api-version=2018-06-01"
$url

# Retrieve credentials one by one via Az.DataFactory module
$ErrorActionPreference = 'Stop'
$r = Invoke-RestMethod -Method Get -Uri $url -Headers $authHeader -ContentType "application/json"
$items = $r.Value
foreach ($i in $items) {
    Write-Host "--- Credential: $($i.name) ..."
    ConvertTo-Json $i -Depth 50 
}

# ------------------
. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session

$adfi = Get-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName"
Write-Host "Azure Data Factory (instance) loaded."
$adfi.DataFactoryId
$adfi.Location

$cr = Get-AzDFV2Credential -adfi $adfi | ToArray
Write-Host ("Credentials: {0} object(s) loaded." -f $cr.Count)
$cr.GetType()
$cr[0].GetType()


