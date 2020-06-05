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
    Write-Debug "Testing config file..."
    Test-Path -Path $configFileName -PathType Leaf | Out-Null 

    $configtxt = Get-Content $configFileName | Out-String
    $configcsv = ConvertFrom-Csv $configtxt 
    $cnt = 0

    $configcsv | ForEach-Object {
        Write-Debug "Item: $_"
        $path = $_.path
        $value = $_.value
        $name = $_.name
        $type = $_.type
        $o = Get-AdfObjectByName -adf $adf -name $name -type $type
        if ($null -eq $o) {
            Write-Error "Could not find object: $type.$name"
        }
        $json = $o.Body
        
        Invoke-Expression "`$fieldType = `$json.properties.$path.GetType()"
        Write-Debug "Type of field [$path] = $fieldType"
        if ($fieldType -eq [String]) {
            $exp = "`$json.properties.$path = `"$value`""
        } else {
            $exp = "`$json.properties.$path = $value"
        }
        Invoke-Expression "$exp"

        # Save new file for deployment purposes and change pointer in object instance
        $f = (Save-AdfObjectAsFile -obj $o)
        $o.FileName = $f

        $cnt++
    }
    Write-Host "*** Replaced $cnt properties. ***`n"

}