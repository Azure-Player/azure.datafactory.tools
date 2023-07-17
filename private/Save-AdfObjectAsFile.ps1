function Save-AdfObjectAsFile {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [AdfObject] $obj
    )
    
    $folder = Join-Path -Path $obj.Adf.Location -ChildPath $($obj.Type)
    if (!(Test-Path $folder)) { 
        Write-Debug "Creating a folder: $folder"
        New-Item -Path $folder -ItemType Directory | Out-Null
    }

    $newFileName = Join-Path -Path $folder -ChildPath "~$($obj.Name).json"
    Write-Debug "Writing file: $newFileName"

    $output = ($obj.Body | ConvertTo-Json -Compress:$true -Depth 100)
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [IO.File]::WriteAllLines($newFileName, $output, $Utf8NoBomEncoding)

    return $newFileName
}
