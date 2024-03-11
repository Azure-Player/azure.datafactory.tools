function Start-Triggers {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adf
    )
    Write-Debug "BEGIN: Start-Triggers()"

    Write-Host ("TriggerStartMethod = $($adf.PublishOptions.TriggerStartMethod)")

    # Determine triggers to be started
    if ($adf.PublishOptions.TriggerStartMethod -eq 'KeepPreviousState') {
        $activeTriggers = $adf.ActiveTriggers | ToArray
    } else {
        $activeTriggers = $adf.Triggers `
        | Where-Object { $_.Body.properties.runtimeState -eq "Started" } | ToArray
    }

    [System.Collections.ArrayList] $toBeStarted = @{}
    if ($null -ne $activeTriggers -and $activeTriggers.Count -gt 0)
    {
        $activeTriggers | ForEach-Object { 
            $isStart = $true
            $triggerName = $_.Name
            [AdfObjectName] $oname = [AdfObjectName]::new("trigger.$triggerName")
            # Check whether a trigger is excluded
            $IsMatchExcluded = $oname.IsNameExcluded($adf.PublishOptions)
            if ($IsMatchExcluded -and $adf.PublishOptions.DoNotStopStartExcludedTriggers) {
                Write-Host "- Excluded trigger: $triggerName" 
                $isStart = $false
            } 
            # Check whether a trigger has been deleted
            if ($isStart -and $adf.IsObjectDeleted("trigger.$triggerName")) {
                Write-Host "- Deleted trigger: $triggerName" 
                $isStart = $false
            }
            # Check whether a (target) trigger is already started
            if ($isStart -and $adf.IsTargetTriggerStarted("$triggerName")) {
                Write-Host "- Trigger already started: $triggerName" 
                $isStart = $false
            }
            if ($isStart) {
                $toBeStarted.Add($triggerName) | Out-Null
            }
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
