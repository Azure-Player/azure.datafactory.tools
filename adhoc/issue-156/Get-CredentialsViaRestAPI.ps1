Get-AzContext
Connect-AzAccount 
Select-AzSubscription -SubscriptionName 'Microsoft Azure Sponsorship'

# Display PowerShell version information
$PSVersionTable

Get-Module
Update-Module Az.Accounts
Import-Module Az.Accounts
Install-Module Az.DataFactory -Scope CurrentUser
Import-Module Az.DataFactory


$testAdf = 'BigFactorySample2'
$DataFactoryName = "$testAdf-7d6cdb5f"
$ResourceGroupName = 'rg-devops-factory'
$adf = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
$adf

# Retrieve all credentials via API without parsing
$url = "https://management.azure.com$($adf.DataFactoryId)/credentials?api-version=2018-06-01"
$url

# Retrieve credentials one by one via Az.DataFactory module
$ErrorActionPreference = 'Stop'

#$r = Invoke-RestMethod -Method Get -Uri $url -Headers $authHeader
#$items = $r.Value

$r = Invoke-AzRestMethod -Method 'Get' -Uri $url
if ($r.StatusCode -ne 200) {
    Write-Host -Message "Unexpected response code: $($r.StatusCode) from the API." -Level Error
    return $null
}
$items = ($r.Content | ConvertFrom-Json).value

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


