function Get-AdfObjectFolderFromService {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [parameter(Mandatory = $true)] $adfInstance,
        [parameter(Mandatory = $true)] [String] $type,
        [parameter(Mandatory = $true)] [String] $name
    )

    Write-Debug "BEGIN: Get-AdfObjectFolderFromService(type=$type, name=$name)"

    # Only these types have folders. Az cmdlets do not return the folder of a pipeline, hence REST API
    $typePlural = switch ($type) {
        'Pipeline' { 'pipelines' }
        'Dataset'  { 'datasets' }
        'DataFlow' { 'dataflows' }
        default    { $null }
    }
    if ($null -eq $typePlural) {
        return ''
    }

    $url = "$($script:BaseApiUrl)$($adfInstance.Id)/$typePlural/$($name)?api-version=2018-06-01"
    $r = Invoke-AdfWithRetry -Activity "Reading folder of [$type].[$name]" -ScriptBlock {
        $resp = Invoke-AzRestMethod -Method 'GET' -Uri $url -ErrorAction Stop
        if ($resp.StatusCode -ne 200) {
            throw "ADFT0036: Unable to read folder of [$type].[$name] from ADF service. Status Code: $($resp.StatusCode)"
        }
        $resp
    }

    $folder = ''
    $props = ($r.Content | ConvertFrom-Json).properties
    if ($null -ne $props -and 'folder' -in $props.PSObject.Properties.Name) {
        $folder = $props.folder.name
    }

    Write-Debug "END: Get-AdfObjectFolderFromService() = '$folder'"
    return $folder
}
