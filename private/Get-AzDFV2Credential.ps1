function Get-AzDFV2Credential {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] $adfi
    )
    Write-Debug "BEGIN: Get-AzDFV2Credential"

    $url = "$($script:BaseApiUrl)$($adfi.DataFactoryId)/credentials?api-version=2018-06-01"

    # Retrieve all credentials via Rest API
    $r = Invoke-AzRestMethod -Method 'GET' -Uri $url
    if ($r.StatusCode -ne 200) {
        Write-Error -Message "Unexpected response code: $($r.StatusCode) from the API."
        return $null
    }

    [System.Collections.ArrayList] $items = @{}
    ($r.Content | ConvertFrom-Json).value | ForEach-Object { $i = [AdfPSCredential]::New($_); $items.Add($i) | Out-Null; }

    Write-Debug "END: Get-AzDFV2Credential()"
    return $items
}


