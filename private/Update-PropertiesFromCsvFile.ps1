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
        $file = Join-Path $srcFolder "$($_.type)\$($_.name).json"
        $newFile = $file
        Write-Debug "File: $file"
        $json = (Get-Content $file | ConvertFrom-Json)
        $prop = "$($_.name).properties.$($_.path) = `"$($_.value)`""
        Write-Verbose "- $prop"
        Invoke-Expression "`$json.properties.$($_.path) = `"$($_.value)`""
        $json | ConvertTo-Json -Depth 10 | Out-File $newFile -Encoding ascii
        $cnt++
    }
    Write-Host "*** Replaced $cnt properties. ***`n"

}