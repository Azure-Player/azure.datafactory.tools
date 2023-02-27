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
        $obj.DependsOn | ForEach-Object {
            $on = [AdfObjectName]::new($_)
            $name = $on.Name
            $type = $on.Type
            Write-Verbose ("$i) Depends on: [$type].[$name]")
            $depobj = Get-AdfObjectByName -adf $adf -name "$name" -type "$type"
            if ($null -eq $depobj) {
                if ($adf.PublishOptions.IgnoreLackOfReferencedObject -eq $true) {
                    Write-Warning "ADFT0006: Referenced object [$type].[$name] was not found. No error raised as user wanted to carry on."
                } else {
                    Write-Error "ADFT0005: Referenced object [$type].[$name] was not found."
                }
            } elseif ($type -notin [AdfObject]::IgnoreTypes) {
                Deploy-AdfObject -obj $depobj
            }
            $i++
        }
    }

    Deploy-AdfObjectOnly -obj $obj

    Write-Host "Finished deploying object: $($obj.FullName($true))"

}
