function Stop-Triggers {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adf
    )
    Write-Debug "BEGIN: Stop-Triggers()"

    Write-Host "Getting triggers..."
    $triggersADF = Get-SortedTriggers -DataFactoryName $adf.Name -ResourceGroupName $adf.ResourceGroupName
    if ($null -ne $triggersADF) 
    {
        # Goal: Stop all active triggers (<>Stopped) present in ADF service
        $triggersToStop = $triggersADF | Where-Object { $_.RuntimeState -ne "Stopped" } | ToArray
        $allAdfTriggersArray = $triggersADF | ToArray
        Write-Host ("The number of triggers to stop: " + $triggersToStop.Count + " (out of $($allAdfTriggersArray.Count))")

        #Stop all triggers
        if ($null -ne $triggersToStop -and $triggersToStop.Count -gt 0)
        {
            Write-Host "Stopping deployed triggers:"
            $triggersToStop | ForEach-Object { 
                [AdfObjectName] $oname = [AdfObjectName]::new("trigger.$($_.Name)")
                $IsMatchExcluded = $oname.IsNameExcluded($adf.PublishOptions)
                if ($IsMatchExcluded -and $adf.PublishOptions.DoNotStopStartExcludedTriggers) {
                    Write-host "- Excluded trigger: $($_.Name)" 
                } else {
                    Stop-Trigger `
                    -ResourceGroupName $adf.ResourceGroupName `
                    -DataFactoryName $adf.Name `
                    -Name $_.Name `
                    | Out-Null
                }
            }
            Write-Host "Complete stopping deployed triggers"
        }

    }

    Write-Debug "END: Stop-Triggers()"
}
