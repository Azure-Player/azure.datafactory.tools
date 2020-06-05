function Save-AdfObjectAsFile {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [AdfObject] $obj
    )
    
    $newFileName = Join-Path $obj.Adf.Location "$($obj.Type)\~$($obj.Name).json"
    Write-Debug "Writing file: $newFileName"

    $output = ($obj.Body | ConvertTo-Json -Compress:$true -Depth 10)
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [IO.File]::WriteAllLines($newFileName, $output, $Utf8NoBomEncoding)

    return $newFileName
}
