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

function Remove-TargetTrigger {
    param (
        $Name,
        $ResourceGroupName,
        $DataFactoryName
    )

    Stop-AzDataFactoryV2Trigger `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Name $Name `
    -Force -ErrorAction:SilentlyContinue

    Remove-AzDataFactoryV2Trigger `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Name $Name `
    -Force -ErrorAction:SilentlyContinue
}

function Stop-TargetTrigger {
    param (
        $Name,
        $ResourceGroupName,
        $DataFactoryName
    )

    Stop-AzDataFactoryV2Trigger `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Name $Name `
    -Force -ErrorAction:SilentlyContinue
}

function Start-TargetTrigger {
    param (
        $Name,
        $ResourceGroupName,
        $DataFactoryName
    )

    Start-AzDataFactoryV2Trigger `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Name $Name `
    -Force -ErrorAction:SilentlyContinue
}

function ConvertTo-RuntimeState {
    param ($state)

    if ($state -eq 'Enabled' ) { return 'Started' }
    if ($state -eq 'Disabled' ) { return 'Stopped' }
    return $state
}

function Publish-TriggerIfNotExist {
    param (
        $Name,
        $FileName,
        $ResourceGroupName,
        $DataFactoryName
    )

    $tr = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $Name -ErrorAction:SilentlyContinue
    if ($null -eq $tr) {
        Set-AzDataFactoryV2Trigger `
        -ResourceGroupName $ResourceGroupName `
        -DataFactoryName $DataFactoryName `
        -Name $Name `
        -DefinitionFile $FileName `
        -Force
    }
}



Export-ModuleMember -Function `
    Convert-SecureStringToString, `
    New-TemporaryDirectory, `
    New-AdfObjectFromFile, `
    Remove-TargetTrigger, ConvertTo-RuntimeState, Stop-TargetTrigger, Start-TargetTrigger, Publish-TriggerIfNotExist
