function Read-JsonConfigFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [Adf] $adf
    )

    Write-Debug "BEGIN: Read-JsonConfigFile(path=$path)"
    $configFileName = $Path
    $option = $adf.PublishOptions

    Write-Debug "Testing config file..."
    Test-Path -Path $configFileName -PathType Leaf | Out-Null 

    #$configFileName = "X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\deployment\config-c100.json"
    $configtxt = Get-Content  $configFileName -Raw | Out-String
    $json = ConvertFrom-Json $configtxt 

    # Creating CSV-like an object
    [System.Collections.ArrayList] $config = @{}

    Set-StrictMode -Version 1.0     # Due to field 'action' which may not exist
    $json.psobject.properties.name | ForEach-Object {
        $name = $_
        $o = $json.($name)
        $o | ForEach-Object {
            $dst = $adf.AllObjects() | Where-Object { $_.Name -like $name } | Select-Object -First 1
            if ($null -ne $dst) {
                $cl = New-Object -TypeName ConfigLine
                $cl.name = $name
                $cl.type = $dst.Type
                $cl.value = $_.value
                $cl.path = $_.name
                if ($_.action -eq "remove") { $cl.path = "-$($cl.path)" }
                if ($_.action -eq "add") { $cl.path = "+$($cl.path)" }
                $null = $config.Add($cl)
            } else {
                if ($option.FailsWhenConfigItemNotFound -eq $false) {
                    Write-Warning "Object [$name] could not be found, skipping..."
                } else {
                    Write-Error "ADFT0017: Object [$name] could not be found."
                }
            }
        }
    }

    # Expanding string (replace Environment Variables with values)
    $config | ForEach-Object {
        $_.value = $ExecutionContext.InvokeCommand.ExpandString($_.value);
    }

    return $config.ToArray()

    Write-Debug "END: Read-JsonConfigFile"

}
