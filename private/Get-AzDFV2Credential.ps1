function Get-AzDFV2Credential {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] $adfi
    )
    Write-Debug "BEGIN: Get-AzDFV2Credential"

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
    $url = "https://management.azure.com$($adfi.DataFactoryId)/credentials?api-version=2018-06-01"

    # Retrieve all credentials via Rest API
    $r = Invoke-RestMethod -Method 'GET' -Uri $url -Headers $authHeader -ContentType "application/json"

    [System.Collections.ArrayList] $items = @{}
    $r.value | ForEach-Object { $i = [AdfPSCredential]::New($_); $items.Add($i) | Out-Null; }

    Write-Debug "END: Get-AzDFV2Credential()"
    return $items
}


