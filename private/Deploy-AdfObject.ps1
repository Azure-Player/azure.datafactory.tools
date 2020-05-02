function Deploy-AdfObject {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [AdfObject] $obj
    )

    if ($obj.ToBeDeployed -eq $false) { 
        Write-Verbose ("Object $($obj.FullName($true)) is not intended to be deployed due to publish options.")
        return; 
    }
    if ($obj.Deployed) { 
        Write-Verbose ("Object $($obj.FullName($true)) is already deployed.")
        return; 
    }
    Write-Host "Start deploying object: $($obj.FullName($true)) ($($obj.DependsOn.Count) dependency/ies)"
    Write-Debug ($obj | Format-List | Out-String)

    $adf = $obj.Adf

    if ($obj.DependsOn.Count -gt 0)
    {
        Write-Debug "Checking all dependencies of [$($obj.Name)]..."
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
