function Get-AdfObjectFolder {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] $adfInstance
    )

    Write-Debug "BEGIN: Get-AdfObjectFolder()"

    # Az cmdlets don't return folders (e.g. PSPipeline has no such property), so read them via REST API.
    # Only pipelines, datasets and data flows can be placed in folders.
    $folders = @{}
    $types = [ordered]@{ 'pipeline' = 'pipelines'; 'dataset' = 'datasets'; 'dataflow' = 'dataflows' }
    foreach ($type in $types.Keys) {
        $url = "$($script:BaseApiUrl)$($adfInstance.Id)/$($types[$type])?api-version=2018-06-01"
        do {
            $r = Invoke-AzRestMethod -Method 'GET' -Uri $url
            if ($r.StatusCode -ne 200) {
                throw "ADFT0035: Unexpected response code: $($r.StatusCode) from REST API when listing $($types[$type])."
            }
            $content = $r.Content | ConvertFrom-Json
            $url = if ($content.PSObject.Properties['nextLink']) { $content.nextLink } else { $null }
            $content.value | ForEach-Object {
                $folder = ''
                $p = $_.properties
                if ($null -ne $p -and $p.PSObject.Properties['folder'] -and $null -ne $p.folder) {
                    $folder = [string] $p.folder.name
                }
                $folders["$type.$($_.name)"] = $folder
            }
        } while ($url)
    }

    Write-Debug "END: Get-AdfObjectFolder()"
    return $folders
}
