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

    $activeTriggersADF = Get-SortedTriggers -DataFactoryName $adf.Name -ResourceGroupName $adf.ResourceGroupName `
    | Where-Object { $_.RuntimeState -ne "Stopped" } | ToArray

    if($obj.Type -match "Trigger")
    {   
        $activeTriggersADF | ForEach-Object {
            if($obj.Name -like $_.Name) {
                Stop-AzDataFactoryV2Trigger `
                -ResourceGroupName $ResourceGroupName `
                -DataFactoryName $DataFactoryName `
                -Name $obj.Name `
                -Force | Out-Null
                Write-Host "Trigger [$($obj.name)] is Started"
                Write-Host "Stopping Trigger before deployment: [$($obj.name)]"
            }
        }
    }
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

    if($obj.Type -match "Trigger")
    {
        $activeTriggersADF | ForEach-Object {
            if($obj.Name -like $_.Name) {
                Start-AzDataFactoryV2Trigger `
                -ResourceGroupName $ResourceGroupName `
                -DataFactoryName $DataFactoryName `
                -Name $obj.Name `
                -Force | Out-Null
                Write-Host "Starting Tigger after deployment: [$($obj.name)]"
            }
        }
    }

    Write-Host "Finished deploying object [$($obj.Name)]."

}
