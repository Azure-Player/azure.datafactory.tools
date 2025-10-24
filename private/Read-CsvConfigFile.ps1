function Read-CsvConfigFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [string] $Path
    )

    Write-Debug "BEGIN: Read-CsvConfigFile(path=$path)"
    $configFileName = $Path

    Write-Debug "Testing config file..."
    Test-Path -Path $configFileName -PathType Leaf | Out-Null 

    $configtxt = Get-Content  $configFileName | Out-String

    # Validation
    Write-Verbose "Validating config file structure..."
    $proc_header = "type","name","path","value","empty"
    $csv = ConvertFrom-Csv $configtxt -Header $proc_header
    if ($csv[0].type + $csv[0].name + $csv[0].path + $csv[0].value + $csv[0].empty + ";" -ne "typenamepathvalue;") {
        Write-Error -Message "ADFT0020: The header of config file is wrong. The header must have only 4 columns named: type, name, path, value." -Category "InvalidData"
    }
    if ($csv.Count -eq 1) {
        Write-Warning "Config file is empty."
    }
    
    # Get actual line numbers for accurate error reporting
    $fileLines = Get-Content $configFileName
    $i = 0
    $csv | ForEach-Object {
        if ($i -gt 0 -and !$_.type.StartsWith("#") ) {
            # Find the actual line number by counting non-empty, non-comment lines up to current CSV row
            $actualLineNumber = 1  # Start with header line
            $csvRowCount = 0
            for ($lineIndex = 1; $lineIndex -lt $fileLines.Count; $lineIndex++) {
                $line = $fileLines[$lineIndex].Trim()
                if ($line -ne "" -and !$line.StartsWith("#")) {
                    $csvRowCount++
                    if ($csvRowCount -eq $i) {
                        $actualLineNumber = $lineIndex + 1  # Convert to 1-based line number
                        break
                    }
                }
            }
            
            if ($_.type -eq "" -or $null -eq $_.type) { Write-Error -Exception ([System.Data.DataException]::new("ADFT0021: Config file, row $actualLineNumber : Value in column 'Type' is empty."))    }
            if ($_.type -notin $ADF_FOLDERS)          { Write-Error -Exception ([System.Data.DataException]::new("ADFT0022: Config file, row $actualLineNumber : Type ($($_.type)) is not supported.")) }
            if ($_.name -eq "" -or $null -eq $_.name) { Write-Error -Exception ([System.Data.DataException]::new("ADFT0023: Config file, row $actualLineNumber : Value in column 'Name' is empty."))    }
            if ($_.path -eq "" -or $null -eq $_.path) { Write-Error -Exception ([System.Data.DataException]::new("ADFT0024: Config file, row $actualLineNumber : Value in column 'Path' is empty."))    }
            if ($_.value -eq "" -or $null -eq $_.value) { 
                if (!$_.path.StartsWith('-')) {
                    Write-Warning -Message "Config file, row $actualLineNumber : Value in column 'Value' is empty." 
                }
            }
            if ($null -ne $_.empty) { Write-Error -Exception ([System.Data.DataException]::new("ADFT0025: Config file, row $actualLineNumber has too many columns.")) }
        }
        $i++
    }
    Write-Host "Validation of config file completed."

    # Final reading
    $csv = ConvertFrom-Csv $configtxt 

    # Expanding string (replace Environment Variables with values)
    $csv | ForEach-Object {
        $_.value = $ExecutionContext.InvokeCommand.ExpandString($_.value);
    }

    return $csv

    Write-Debug "END: Read-CsvConfigFile"

}