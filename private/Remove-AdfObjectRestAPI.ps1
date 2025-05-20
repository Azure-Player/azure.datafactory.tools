function Remove-AdfObjectRestAPI {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] $type_plural,
        [parameter(Mandatory = $true)] $name,
        [parameter(Mandatory = $true)] $adfInstance
    )

    Write-Debug "BEGIN: Remove-AdfObjectRestAPI()"

    $token = Get-AzAccessToken -ResourceUrl $script:BaseApiUrl
    # With Az.Accounts 5.x, the token is a SecureString. Convert it to plain text before using.
    $plainToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($token.Token)
    )
    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $plainToken
    }
    $url = "$($script:BaseApiUrl)$($adfInstance.Id)/$type_plural/$($name)?api-version=2018-06-01"

    # Delete given object via Rest API
    $r = Invoke-RestMethod -Method 'DELETE' -Uri $url -Headers $authHeader -ContentType "application/json"

    Write-Debug "END: Remove-AdfObjectRestAPI()"
}


# https://learn.microsoft.com/en-us/rest/api/datafactory/credential-operations/delete?tabs=HTTP
