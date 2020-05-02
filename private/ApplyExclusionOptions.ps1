function ApplyExclusionOptions {
    param(
        [Parameter(Mandatory=$True)] [Adf] $adf,
        [Parameter(Mandatory=$True)] [AdfPublishOption] $option
    )

    Write-Debug "BEGIN: ApplyExclusionOptions()"
    
    if ($option.Excludes.Keys.Count -gt 0 -and $option.Includes.Keys.Count -eq 0)
    {
        Write-Debug "ENTRY: ApplyExclusionOptions()::Excludes"
        $adf.AllObjects() | ForEach-Object {
            [AdfObject] $o = $_
            $o.ToBeDeployed = $true
        }
        $option.Excludes.Keys | ForEach-Object {
            $key = $_
            $adf.AllObjects() | ForEach-Object {
                [AdfObject] $o = $_
                $nonDeployable = ($o.FullName($false) -like $key)
                #Write-Debug "$($o.FullName($false)) -like $key"
                if ($nonDeployable) { $o.ToBeDeployed = $false }
                #Write-Verbose "- $($o.FullName($true)).ToBeDeployed = $($o.ToBeDeployed)"
            }
        }
    }
    
    if ($option.Includes.Keys.Count -gt 0)
    {
        Write-Debug "ENTRY: ApplyExclusionOptions()::Includes"
        $adf.AllObjects() | ForEach-Object {
            [AdfObject] $o = $_
            $o.ToBeDeployed = $false
        }
        $option.Includes.Keys | ForEach-Object {
            $key = $_
            $adf.AllObjects() | ForEach-Object {
                [AdfObject] $o = $_
                $deployable = ($o.FullName($false) -like $key)
                #Write-Debug "$($o.FullName($false)) -like $key"
                if ($deployable) { $o.ToBeDeployed = $true }
                #Write-Verbose "- $($o.FullName($true)).ToBeDeployed = $($o.ToBeDeployed)"
            }
        }
    }

    $ToBeDeployedList = ($adf.AllObjects() | Where-Object { $_.ToBeDeployed -eq $true } | ToArray)
    $i = $ToBeDeployedList.Count
    Write-Host "# Number of objects marked as to be deployed: $i/$($adf.AllObjects().Count)"
    $ToBeDeployedList | ForEach-Object {
        Write-Host "- $($_.FullName($true))"
    }


    Write-Debug "END: ApplyExclusionOptions()"
}

