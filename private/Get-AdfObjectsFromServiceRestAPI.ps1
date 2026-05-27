function Get-AdfObjectsFromServiceRestAPI {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] $adfi,
        [parameter(Mandatory = $true)] [String] $typePlural,
        [parameter(Mandatory = $true)] [String] $simpleType
    )

    Write-Debug "BEGIN: Get-AdfObjectsFromServiceRestAPI(typePlural=$typePlural, simpleType=$simpleType)"

    $url = "$($script:BaseApiUrl)$($adfi.DataFactoryId)/$typePlural`?api-version=2018-06-01"
    $r = Invoke-AzRestMethod -Method 'GET' -Uri $url
    if ($r.StatusCode -ne 200) {
        Write-Error -Message "Unexpected response code: $($r.StatusCode) from REST API when listing $typePlural."
        return $null
    }

    [System.Collections.ArrayList] $items = @()
    ($r.Content | ConvertFrom-Json).value | ForEach-Object {
        $name = $_.name
        $obj = $null
        switch ($simpleType) {
            'Dataset'            { $obj = [AdfPSDataset]::New($name) }
            'DataFlow'           { $obj = [AdfPSDataFlow]::New($name) }
            'Pipeline'           { $obj = [AdfPSPipeline]::New($name) }
            'LinkedService'      { $obj = [AdfPSLinkedService]::New($name) }
            'IntegrationRuntime' { $obj = [AdfPSIntegrationRuntime]::New($name) }
            'Trigger'            { $obj = [AdfPSTrigger]::New($name, [string]$_.properties.runtimeState) }
            default              { Write-Warning "Get-AdfObjectsFromServiceRestAPI: unsupported type '$simpleType'" }
        }
        if ($null -ne $obj) { $items.Add($obj) | Out-Null }
    }

    Write-Debug "END: Get-AdfObjectsFromServiceRestAPI()"
    return $items
}
