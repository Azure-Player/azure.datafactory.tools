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
    $fullTmpPath = Join-Path $parent $name
    New-Item -ItemType Directory -Path $fullTmpPath
    Write-Host "Created folder: $fullTmpPath"
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

    $tr = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -TriggerName $Name #-ErrorAction:SilentlyContinue
    if ($null -eq $tr) {
        $f = $FileName.ToString()
          Set-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $Name -DefinitionFile $f
        #-Force
    }
}

function Get-AdfObjectFromFile {
    param ($FullPath)

    $txt = Get-Content $FullPath -Encoding "UTF8"
    $o = $o = [AdfObject]::new()
    $o.Name = (Split-Path -Path $FullPath -Leaf)
    $o.FileName = $FullPath
    $o.Body = $txt | ConvertFrom-Json
    return $o
}


function Remove-ObjectPropertyFromFile {
    param (
        $FileName,
        $Path
    )

    $j = Get-Content -Path $FileName -Raw -Encoding 'utf8' | ConvertFrom-Json
    $j.PSObject.Properties.Remove($Path)
    $output = ($j | ConvertTo-Json -Compress:$true -Depth 100)
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [IO.File]::WriteAllLines($FileName, $output, $Utf8NoBomEncoding)
}

function Edit-ObjectPropertyInFile {
    param (
        $FileName,
        $Path,
        $Value
    )

    $j = Get-Content -Path $FileName -Raw -Encoding 'utf8' | ConvertFrom-Json
    $exp = "`$j.$Path = $Value"
    Write-Host "Expression to run: $exp"
    Invoke-Expression "$exp"
    $output = ($j | ConvertTo-Json -Compress:$true -Depth 100)
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [IO.File]::WriteAllLines($FileName, $output, $Utf8NoBomEncoding)
}


function Edit-TextInFile {
    param (
        $FileName,
        $ReplaceText,
        $NewText
    )

    $raw = Get-Content -Path $FileName -Raw -Encoding 'utf8'
    $output = $raw -replace $ReplaceText, $NewText
    if ($raw -eq $output) { Write-Error "TestHelper.Edit-TextInFile: Content of the file hasn't been updated." }
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [IO.File]::WriteAllLines($FileName, $output, $Utf8NoBomEncoding)
}


function Backup-File {
    param (
        $FileName
    )

    $CopyFileName = "$FileName.backup"
    Copy-Item $FileName $CopyFileName
    return $CopyFileName
}

function Restore-File {
    param (
        [String] $FileName,
        $RemoveBackup = $true
    )

    if ($FileName.EndsWith('.backup')) {
        $OriginalFileName = $FileName.Substring(0, $FileName.Length - 7)
        Copy-Item $FileName $OriginalFileName
        if ($RemoveBackup) {
            Remove-Item -Path $FileName
        }
    }
}

function Get-RootPath {
    $rootPath = Switch ($Host.name) {
        'Visual Studio Code Host' { Split-Path $psEditor.GetEditorContext().CurrentFile.Path }
        'Windows PowerShell ISE Host' { Split-Path -Path $psISE.CurrentFile.FullPath }
        'ConsoleHost' { $PSScriptRoot }
    }
    #$rootPath = Split-Path $rootPath -Parent
    return $rootPath;
}

function Get-TargetEnv {
    param (
        [String] $AdfOrigName
    )

    $rootPath = Get-RootPath
    $target = @{
        ResourceGroupName = 'rg-devops-factory'
        DataFactoryOrigName = $AdfOrigName
        DataFactoryName = ""
        Location = "UK South"
        SrcFolder = "$rootPath\$AdfOrigName"
    }
    $c = Get-AzContext
    $guid = $c.Subscription.Id.Substring(0,8)
    $target.DataFactoryName = $AdfOrigName + "-$guid"
    return $target
}

function IsPesterDebugMode {
    return ($Output -eq 'Diagnostic');
}

Write-Host "Importing MockDataFactory..."
$filePath = $PSScriptRoot | Join-Path -ChildPath 'MockDataFactory.ps1'
. $filePath

function CreateTargetAdf {
    $TargetAdf = New-Object -TypeName "MockTargetAdf"
    return $TargetAdf
}



Export-ModuleMember -Function `
    Convert-SecureStringToString, `
    New-TemporaryDirectory, `
    New-AdfObjectFromFile, `
    Remove-TargetTrigger, ConvertTo-RuntimeState, Stop-TargetTrigger, Start-TargetTrigger, Publish-TriggerIfNotExist, `
    Get-AdfObjectFromFile, `
    Remove-ObjectPropertyFromFile, Edit-TextInFile, Edit-ObjectPropertyInFile, `
    Backup-File, Restore-File, `
    Get-RootPath, Get-TargetEnv, IsPesterDebugMode, CreateTargetAdf
