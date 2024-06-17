<#
.SYNOPSIS
Validates files of ADF in a given location, returning warnings or errors.

.DESCRIPTION
Validates files of ADF in a given location. The following validation will be perform:
- Reads all files and validates its json format
- Checks whether all dependant objects exist
- Checks whether file name equals object name

.PARAMETER RootFolder
Source folder where all ADF objects are kept. The folder should contain subfolders like pipeline, linkedservice, etc.

.EXAMPLE
Test-AdfCode -RootFolder "$RootFolder"

#>
function Test-AdfCode {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] 
        [String] $RootFolder,
        [parameter(Mandatory = $false)] 
        [String] $ConfigPath
    )

    class ReturnClass {
        [int] $ErrorCount
        [int] $WarningCount 
    }
    $result = New-Object 'ReturnClass'

    $result.ErrorCount = 0
    $result.WarningCount = 0
    $adfName = Split-Path -Path "$RootFolder" -Leaf

    Write-Host "=== Loading files from location: $RootFolder ..."
    if (-not (Test-Path -Path $RootFolder)) {
        Write-Error "Location doesn't exist: $RootFolder"
        return $result
    }
    $adf = Import-AdfFromFolder -FactoryName "$adfName" -RootFolder "$RootFolder" -ErrorAction "SilentlyContinue"
    $adf.PublishOptions = New-AdfPublishOption
    $ObjectsCount = $adf.AllObjects().Count

    Write-Host "=== Validating files ..."

    $ErrorActionPreference = 'Continue'

    if ($ObjectsCount -eq 0) {
        $result.WarningCount += 1
        Write-Warning "No Azure Data Factory files have been found in a given location."
    }

    $adf.AllObjects() | ForEach-Object {
        $FullName = $_.FullName($true)
        Write-Host "Checking: $FullName..."
        $HasBody = $null -ne $_.Body
        if (-not $HasBody) {
            $result.ErrorCount += 1
            Write-Error -Message "Object $FullName was not loaded properly." -ErrorAction 'Continue'
        }
        if ($HasBody) {

            if ($_.name -ne $_.Body.name) {
                $result.ErrorCount += 1
                Write-Error -Message "Object $FullName has mismatch file name." -ErrorAction 'Continue'
            }

            $_.DependsOn | ForEach-Object {
                Write-Verbose -Message "  - Checking dependency: [$_]"
                $ref_arr = $adf.GetObjectsByFullName("$_")
                $refName = [AdfObjectName]::new($_)
                if ($ref_arr.Count -eq 0 -and $refName.Type -notin [AdfObject]::IgnoreTypes) {
                    $result.ErrorCount += 1
                    Write-Error -Message "Couldn't find referenced object $_." -ErrorAction 'Continue'
                }
            }
        }
    }

    Write-Host "=== Validating other rules ..."

    Write-Host "Checking duplicated names..."
    $adf.AllObjects().Name | Sort-Object -Unique | ForEach-Object {
        $r = $adf.GetObjectsByFullName("*." + $_)
        if ($r.Count -gt 1) {
            Write-Warning "Duplication of object name: $_"
            $result.WarningCount += 1
        }
    }

    Write-Host "Checking names of linkedservices, datasets, dataflows..."
    $adf.LinkedServices + $adf.DataSets + $adf.DataFlows | ForEach-Object {
        [string] $name = $_.Name
        if ($name.Contains('-')) {
            Write-Warning "Dashes ('-') are not allowed in the names of linked services, data flows, and datasets ($name)."
            $result.WarningCount += 1
        }
    }

    Write-Host "Checking: Global parameter names..."
    if ($adf.Factories.Count -gt 0) {
        $gparams = $adf.GlobalFactory.GlobalParameters
        if ($gparams) {
            Get-Member -InputObject $gparams -Membertype "NoteProperty" | ForEach-Object {
                [string] $name = $_.Name
                if ($name.Contains('-')) {
                    Write-Warning "Dashes ('-') are not allowed in the names of global parameters ($name)."
                    $result.WarningCount += 1
                }
            }
        }
    }


    Write-Host "=== Validating config files ..."
    $filePattern = $null
    if (!$ConfigPath) {
        $filePattern = Join-Path -Path $adf.Location -ChildPath 'deployment\*' 
        if (!(Test-Path $filePattern)) { $filePattern = $null }
    } else {
        $filePattern = $ConfigPath -split ','
    }

    if ($filePattern) {
        $files = Get-ChildItem -Path $filePattern -Include '*.csv','*.json'
        $err = $null
        $adf.PublishOptions.FailsWhenConfigItemNotFound = $True
        $adf.PublishOptions.FailsWhenPathNotFound = $True
        $files | ForEach-Object { 
            try {
                $FileName = $_.FullName
                Write-Host "Checking config file: $FileName..."
                Update-PropertiesFromFile -adf $adf -stage $FileName -ErrorVariable err -ErrorAction 'Stop' -dryRun:$True
            }
            catch {
                $result.ErrorCount += 1
                Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor 'Red'
                Write-Debug -Message $_.Exception
                #$_.Exception
            }
        }
    } else {
        Write-Host "ConfigPath is not set or Location doesn't exist. Skipping config files validation."
    }

    
    $msg = "Test code completed ($ObjectsCount objects)."
    if ($result.ErrorCount -gt 0) { $msg = "Test code failed." }
    $line1 = $adf.Name.PadRight(63) + "  # of Errors: $($result.ErrorCount)".PadLeft(28)
    $line2 = $msg.PadRight(63)      + "# of Warnings: $($result.WarningCount)".PadLeft(28)
    Write-Host "============================================================================================="
    Write-Host " $line1"
    Write-Host " $line2"
    Write-Host "============================================================================================="

    return $result;
}
