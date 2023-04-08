function Update-PropertiesFromFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [Adf] $adf,
        [Parameter(Mandatory)] [string] $stage,
        [switch] $dryRun = $false
        )

    Write-Debug "BEGIN: Update-PropertiesFromFile(adf=$adf, stage=$stage)"

    $option = $adf.PublishOptions
    $srcFolder = $adf.Location
    if ([string]::IsNullOrEmpty($srcFolder)) {
        Write-Error "ADFT0011: adf.Location property has not been provided."
    }
    
    $ext = "CSV"
    if ($stage.EndsWith(".csv")) { 
        $configFileName = $stage 
    } elseif ($stage.EndsWith(".json")) {
        $configFileName = $stage 
        $ext = "JSON"
    } 
    else {
        $configFileName = Join-Path $srcFolder "deployment\config-$stage.csv"
    }

    Write-Verbose "Replacing values for ADF properties from $ext config file"
    Write-Host "Config file:   $configFileName"

    if ($ext -eq "CSV") {
        $config = Read-CsvConfigFile -Path $configFileName
    } else {
        $config = Read-JsonConfigFile -Path $configFileName -adf $adf
    }
    #$config | Out-Host 

    $report = new-object PsObject -Property @{
        Updated = 0
        Added = 0
        Removed = 0
    }

    $config | ForEach-Object {
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

        $objArr = Get-AdfObjectByPattern -adf $adf -name $name -type $type
        if ($null -eq $objArr) {
            if ($option.FailsWhenConfigItemNotFound -eq $false) {
                Write-Warning "Could not find object: $type.$name, skipping..."
            } else {
                Write-Error -Message "ADFT0007: Could not find object: $type.$name"
            }
        } else {
            Write-Verbose "- Performing: $action for object(path): $type.$name(properties.$path)"
            $objArr | ForEach-Object {
                $null = Update-PropertiesForObject -o $_ -action $action -path $path -value $value -name $name -type $type -report $report -dryRun:$dryRun
            }
        }
    }
    Write-Host "*** Properties modification report ***"
    $report | Out-Host 

    Write-Debug "END: Update-PropertiesFromFile"

}


function Update-PropertiesForObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]          [AdfObject] $o,
        [Parameter(Mandatory)]          [string] $action,
        [Parameter(Mandatory)]          [string] $path,
        [AllowEmptyString()]            $value,
        [Parameter(Mandatory)]          [string] $name,
        [Parameter(Mandatory)]          [string] $type,
        [Parameter(Mandatory)]          $report,
                                        [switch] $dryRun = $false
    )

    Write-Debug "BEGIN: Update-PropertiesForObject"

    # if ($null -eq $o -and $action -ne "add") {
    #     Write-Error "ADFT0008: Could not find object: $type.$name"
    # }
    $json = $o.Body | ConvertFrom-ArraysToOrderedHashTables
    if ($null -eq $json) {
        Write-Error "ADFT0009: Body of the object is empty!"
    }
    
    $objName = $o.Name
    if ($objName -ne $name) { 
        Write-Verbose "  - Matched object: $type.$objName(properties.$path)"
    }

    $validPath = $true

    try {
        if ($action -ne "add") {
            Invoke-Expression "`$isExist = (`$null -ne `$json.properties.$path)"
        }
    }
    catch {
        $validPath = $false

        if ($option.FailsWhenPathNotFound -eq $false) {
            Write-Warning "Wrong path defined in config for object(path): $type.$name(properties.$path), skipping..."
        } else {
            $exc = ([System.Data.DataException]::new("ADFT0010: Wrong path defined in config for object(path): $type.$name(properties.$path)"))
            Write-Error -Exception $exc
        }
    }

    if ($validPath) {
        switch -Exact ($action)
        {
            'update'
            {
                Update-ObjectProperty -obj $json -path "properties.$path" -value $value
                $report.Updated += 1
            }
            'add'
            {
                Add-ObjectProperty -obj $json -path "properties.$path" -value $value
                $report.Added += 1
            }
            'remove'
            {
                Remove-ObjectProperty -obj $json -path "properties.$path"
                $report.Removed += 1
            }
        }
    }

    $o.Body = $json | ConvertFrom-OrderedHashTablesToArrays

    # Save new file for deployment purposes and change pointer in object instance
    if ($dryRun -eq $False) 
    {
        $f = (Save-AdfObjectAsFile -obj $o)
        $o.FileName = $f
    }
    
    Write-Debug "END: Update-PropertiesForObject"

}    