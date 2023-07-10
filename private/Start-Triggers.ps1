function Start-Triggers {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adf
    )
    Write-Debug "BEGIN: Start-Triggers()"

    Write-Host ("TriggerStartMethod = $($adf.PublishOptions.TriggerStartMethod)")

    # Determine triggers to be started
    [AdfObject[]] $activeTrigger
    if ($adf.PublishOptions.TriggerStartMethod -eq 'KeepPreviousState') {
        $activeTrigger = $adf.activeTriggers | ToArray
    } else {
        $activeTrigger = $adf.Triggers `
        | Where-Object { $_.Body.properties.runtimeState -eq "Started" } | ToArray
    }

    [System.Collections.ArrayList] $toBeStarted = @{}
    $activeTrigger | ForEach-Object { 
        $isStart = $true
        $triggerName = $_.Name
        [AdfObjectName] $oname = [AdfObjectName]::new("trigger.$triggerName")
        # Check whether a trigger is excluded
        $IsMatchExcluded = $oname.IsNameExcluded($adf.PublishOptions)
        if ($IsMatchExcluded -and $adf.PublishOptions.DoNotStopStartExcludedTriggers) {
            Write-host "- Excluded trigger: $triggerName" 
            $isStart = $false
        } 
        # Check whether a trigger has been deleted
        if ($isStart -and $adf.IsObjectDeleted("trigger.$triggerName")) {
            Write-host "- Deleted trigger: $triggerName" 
            $isStart = $false
        }
        if ($isStart) {
            $toBeStarted.Add($triggerName)
        }
    }

    Write-Host ("The number of triggers to start: " + $toBeStarted.Count)

    # Start triggers
    if ($toBeStarted.Count -gt 0)
    {
        Write-Host "Starting triggers:"
        $toBeStarted | ForEach-Object { 
            Start-Trigger `
            -ResourceGroupName $adf.ResourceGroupName `
            -DataFactoryName $adf.Name `
            -Name $_ `
            | Out-Null
        }
        Write-Host "Complete starting triggers."
    }

    Write-Debug "END: Start-Triggers()"
}
