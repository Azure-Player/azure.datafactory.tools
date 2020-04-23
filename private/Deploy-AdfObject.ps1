function Deploy-AdfObject {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [AdfObject] $obj
    )

    if ($obj.Deployed) { 
        Write-Verbose ("Object [$($obj.Name)] is already deployed.")
        return; 
    }
    Write-Host "Start deploying object: [$($obj.Name)] ($($obj.DependsOn.Count) dependency/ies)"
    Write-Verbose "  Type: $($obj.Type)"
    Write-Debug ($obj | Format-List | Out-String)

    $adf = $obj.Adf

    if ($obj.DependsOn.Count -gt 0)
    {
        Write-Verbose "Checking all dependencies of [$($obj.Name)]..."
        $i = 1
        $obj.DependsOn.getEnumerator() | ForEach-Object {
            $name = $_.key
            $type = $_.value
            Write-Verbose ("$i) Depends on: [$type].[$name]")
            $depobj = Get-AdfObjectByName -adf $adf -name "$name" -type "$type"
            if ($null -eq $depobj) {
                Write-Error "Referenced object [$name] was not found."
            } else {
                Deploy-AdfObject -obj $depobj
            }
            $i++
        }
    }

    Deploy-AdfObjectOnly -obj $obj

    Write-Host "Finished deploying object [$($obj.Name)]."

}
