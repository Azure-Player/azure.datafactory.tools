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

    $ErrorCount = 0
    $WarningCount = 0
    $adfName = Split-Path -Path "$RootFolder" -Leaf

    Write-Host "=== Loading files from location: $RootFolder ..."
    $adf = Import-AdfFromFolder -FactoryName "$adfName" -RootFolder "$RootFolder" -ErrorAction "SilentlyContinue"
    $adf.PublishOptions = New-AdfPublishOption
    $ObjectsCount = $adf.AllObjects().Count

    Write-Host "=== Validating files ..."

    $ErrorActionPreference = 'Continue'

    if ($ObjectsCount -eq 0) {
        $WarningCount += 1
        Write-Warning "No Azure Data Factory files have been found in a given location."
    }

    $adf.AllObjects() | ForEach-Object {
        $FullName = $_.FullName($true)
        Write-Host "Checking: $FullName..."
        $HasBody = $null -ne $_.Body
        if (-not $HasBody) {
            $ErrorCount += 1
            Write-Error -Message "Object $FullName was not loaded properly."
        }
        if ($HasBody) {

            if ($_.name -ne $_.Body.name) {
                $ErrorCount += 1
                Write-Error -Message "Object $FullName has mismatch file name."
            }

            $_.DependsOn | ForEach-Object {
                Write-Verbose -Message "  - Checking dependency: [$_]"
                $ref_arr = $adf.GetObjectsByFullName("$_")
                if ($ref_arr.Count -eq 0) {
                    $ErrorCount += 1
                    Write-Error -Message "Couldn't find referenced object $_."
                }
            }
        }
    }

    Write-Host "=== Validating other rules ..."

    $adf.AllObjects().Name | Sort-Object -Unique | ForEach-Object {
        $r = $adf.GetObjectsByFullName("*." + $_)
        if ($r.Count -gt 1) {
            Write-Warning "Duplication of object name: $_"
            $WarningCount += 1
        }
    }

    $adf.LinkedServices + $adf.DataSets + $adf.Pipelines + $adf.DataFlows | ForEach-Object {
        [string] $name = $_.Name
        if ($name.Contains('-')) {
            Write-Warning "Dashes ('-') are not allowed in the names of linked services, data flows, and datasets ($name)."
            $WarningCount += 1
        }
    }

    if ($adf.Factories.Count -gt 0 -and (Get-Member -InputObject $adf.Factories[0].Body -name "properties" -Membertype "Properties")) {
        Get-Member -InputObject $adf.Factories[0].Body.properties.globalParameters -Membertype "NoteProperty" | ForEach-Object {
            [string] $name = $_.Name
            if ($name.Contains('-')) {
                Write-Warning "Dashes ('-') are not allowed in the names of global parameters ($name)."
                $WarningCount += 1
            }
        }
    }


    Write-Host "=== Validating config files ..."
    if (!$ConfigPath) {
        $filePattern = Join-Path -Path $adf.Location -ChildPath 'deployment\*' 
        if (!(Test-Path $filePattern)) { $filePattern = $null }
    } else {
        $filePattern = $ConfigPath -split ','
    }

    $files = Get-ChildItem -Path $filePattern -Include '*.csv','*.json'
    $err = $null
    $adf.PublishOptions.FailsWhenConfigItemNotFound = $True
    $adf.PublishOptions.FailsWhenPathNotFound = $True
    $files | ForEach-Object { 
        try {
            $FileName = $_.FullName
            Update-PropertiesFromFile -adf $adf -stage $FileName -ErrorVariable err -ErrorAction 'Stop' -dryRun:$True
        }
        catch {
            $ErrorCount += 1
            Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor 'Red'
            Write-Debug -Message $_.Exception
            #$_.Exception
        }
    }


    
    $msg = "Test code completed ($ObjectsCount objects)."
    if ($ErrorCount -gt 0) { $msg = "Test code failed." }
    $line1 = $adf.Name.PadRight(63) + "  # of Errors: $ErrorCount".PadLeft(28)
    $line2 = $msg.PadRight(63)      + "# of Warnings: $WarningCount".PadLeft(28)
    Write-Host "============================================================================================="
    Write-Host " $line1"
    Write-Host " $line2"
    Write-Host "============================================================================================="

    return $ErrorCount;
}
