function Remove-AdfObjectRestAPI {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] $type_plural,
        [parameter(Mandatory = $true)] $name,
        [parameter(Mandatory = $true)] $adfInstance
    )

    Write-Debug "BEGIN: Remove-AdfObjectRestAPI()"

    $token = Get-AzAccessToken -ResourceUrl 'https://management.azure.com'
    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $token.Token
    }
    $url = "https://management.azure.com$($adfInstance.Id)/$type_plural/$($name)?api-version=2018-06-01"

    # Delete given object via Rest API
    $r = Invoke-RestMethod -Method 'DELETE' -Uri $url -Headers $authHeader -ContentType "application/json"

    Write-Debug "END: Remove-AdfObjectRestAPI()"
}


# https://learn.microsoft.com/en-us/rest/api/datafactory/credential-operations/delete?tabs=HTTP
