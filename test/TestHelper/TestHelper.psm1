# This module provides helper functions for executing tests


<#
    .SYNOPSIS
        Decrypt a Secure String back to a string.
#>
function Convert-SecureStringToString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Security.SecureString]
        $SecureString
    )

    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}


function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = 'ADFTools-' + [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}


function New-AdfObjectFromFile {
    [OutputType([AdfObject])]
    param (
        $fileRelativePath,
        $type,
        $name
    )

    $o = [AdfObject]::new()
    $filename = Join-Path -Path (Get-Location) -ChildPath $fileRelativePath
    $txt = Get-Content $filename -Encoding "UTF8"
    $o.Name = $name
    $o.Type = $type
    $o.FileName = $filename
    $o.Body = $txt | ConvertFrom-Json
    return $o
}


Export-ModuleMember -Function `
    Convert-SecureStringToString, `
    New-TemporaryDirectory, `
    New-AdfObjectFromFile
    
