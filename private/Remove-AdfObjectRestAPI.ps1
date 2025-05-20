function Remove-AdfObjectRestAPI {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] $type_plural,
        [parameter(Mandatory = $true)] $name,
        [parameter(Mandatory = $true)] $adfInstance
    )

    Write-Debug "BEGIN: Remove-AdfObjectRestAPI()"

    $url = "$($script:BaseApiUrl)$($adfInstance.Id)/$type_plural/$($name)?api-version=2018-06-01"

    # Delete given object via Rest API
    $r = Invoke-AzRestMethod -Method 'DELETE' -Uri $url #-Headers $authHeader -ContentType "application/json"
    if ($r.StatusCode -ne 200) {
        Write-Error -Message "Unexpected response code: $($r.StatusCode) from the API."
    }

    Write-Debug "END: Remove-AdfObjectRestAPI()"
}


# https://learn.microsoft.com/en-us/rest/api/datafactory/credential-operations/delete?tabs=HTTP
