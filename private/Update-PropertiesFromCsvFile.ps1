function Update-PropertiesFromCsvFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [Adf] $adf,
        [Parameter(Mandatory)] [string] $stage
        )

    Write-Debug "BEGIN: Update-PropertiesFromCsvFile(adf=$adf, stage=$stage)"

    $srcFolder = $adf.Location
    if ([string]::IsNullOrEmpty($srcFolder)) {
        Write-Error "adf.Location property has not been provided."
    }
    
    if ($stage.EndsWith(".csv")) { 
        $configFileName = $stage 
    } else {
        $configFileName = Join-Path $srcFolder "deployment\config-$stage.csv"
    }

    Write-Verbose "Replacing values for ADF properties from CSV config file"
    Write-Host "Config file:   $configFileName"

    $configcsv = Read-CsvConfigFile -Path $configFileName

    $report = @{ Updated = 0; Added = 0; Removed = 0}
    $configcsv | ForEach-Object {
        Write-Debug "Item: $_"
        $path = $_.path
        $value = $_.value
        $name = $_.name
        $type = $_.type

        # Omit commented lines
        if ($type.StartsWith('#')) { 
            Write-Debug "Skipping this line..."
            return      # return is like continue for foreach and go to next item in collection
        }

        $action = "update"
        if ($path.StartsWith('+')) { 
            $action = 'add';
            $path = $path.Substring(1)
        }
        if ($path.StartsWith('-')) { 
            $action = 'remove';
            $path = $path.Substring(1)
        }
        if ($path.StartsWith("`$.properties.")) { 
            $path = $path.Substring(13) 
        }

        $o = Get-AdfObjectByName -adf $adf -name $name -type $type
        if ($null -eq $o -and $action -ne "add") {
            Write-Error "Could not find object: $type.$name"
        }
        $json = $o.Body
        
        Write-Verbose "- Performing: $action for path: properties.$path"
        try {
            if ($action -ne "add") {
                Invoke-Expression "`$isExist = (`$null -ne `$json.properties.$path)"
            }
        }
        catch {
            $exc = ([System.Data.DataException]::new())
            Write-Error -Message "Wrong path defined in config for object(path): $type.$name(properties.$path)" -Exception $exc
        }

        switch -Exact ($action)
        {
            'update'
            {
                Update-ObjectProperty -obj $json -path "properties.$path" -value "$value"
                $report['Updated'] += 1
            }
            'add'
            {
                Add-ObjectProperty -obj $json -path "properties.$path" -value "$value"
                $report['Added'] += 1
            }
            'remove'
            {
                Remove-ObjectProperty -obj $json -path "properties.$path"
                $report['Removed'] += 1
            }
        }

        # Save new file for deployment purposes and change pointer in object instance
        $f = (Save-AdfObjectAsFile -obj $o)
        $o.FileName = $f

    }
    Write-Host "*** Properties modification report ***"
    $report | Out-Host 

    Write-Debug "END: Update-PropertiesFromCsvFile"

}

