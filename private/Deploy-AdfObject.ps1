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
        $obj.DependsOn | ForEach-Object {
            $name = $_
            Write-Verbose ("$i) Depends on: {0}" -f $name)
            #$adf
            $depobj = Get-AdfObjectByName -adf $adf -name $name
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
