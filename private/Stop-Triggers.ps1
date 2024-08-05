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
        $activeTriggers = $triggersADF | Where-Object { $_.RuntimeState -ne "Stopped" } | ToArray
        $adf.activeTriggers = $activeTriggers       # Remember to use after the deployment when TriggerStartMethod = 'KeepPreviousState'
        $allAdfTriggersArray = $triggersADF | ToArray
        $adf.SetTargetTriggerNames($allAdfTriggersArray)
        Write-Host ("The number of active triggers: " + $activeTriggers.Count + " (out of $($allAdfTriggersArray.Count))")
        Write-Host ("TriggerStopMethod = $($adf.PublishOptions.TriggerStopMethod)")

        # Determine triggers to be stopped
        [System.Collections.ArrayList] $toBeStopped = @{}
        if ($null -ne $activeTriggers -and $activeTriggers.Count -gt 0)
        {
            $activeTriggers | ForEach-Object { 
                $deploy = $true
                $triggerName = $_.Name
                [AdfObjectName] $oname = [AdfObjectName]::new("trigger.$triggerName")
                # Check whether a trigger is not for deployment
                if ($adf.PublishOptions.TriggerStopMethod -eq 'DeployableOnly') {
                    $sourceObject = Get-AdfObjectByName -adf $adf -name $triggerName -type 'Trigger'
                    if ($null -eq $sourceObject -or $sourceObject.ToBeDeployed -eq $false) {
                        Write-Host "- Ignored trigger: $triggerName"
                        $deploy = $false
                    }
                }
                # Check whether a trigger is excluded
                if ($deploy) {
                    $IsMatchExcluded = $oname.IsNameExcluded($adf.PublishOptions)
                    if ($IsMatchExcluded -and $adf.PublishOptions.DoNotStopStartExcludedTriggers) {
                        Write-Host "- Excluded trigger: $triggerName"
                        $deploy = $false
                    } 
                }
                if ($deploy) {
                    $toBeStopped.Add($triggerName) | Out-Null
                }
            }
        }
        Write-Host ("The number of triggers to stop: " + $toBeStopped.Count)

        # Stop triggers
        if ($toBeStopped.Count -gt 0)
        {
            Write-Host "Stopping deployed triggers:"
            $toBeStopped | ForEach-Object { 
                Stop-Trigger `
                -ResourceGroupName $adf.ResourceGroupName `
                -DataFactoryName $adf.Name `
                -Name $_ `
                | Out-Null
                
                $TrName = $_
                $adf.TargetTriggerNames | Where-Object { $_.Name -eq $TrName } | ForEach-Object { $_.RuntimeState = "Stopped" }
            }
            Write-Host "Complete stopping deployed triggers."
        }
        $adf.StoppedTriggerNames = $toBeStopped
    }
    else 
    {
        Write-Host ("No remote triggers found.")
    }

    Write-Debug "END: Stop-Triggers()"
}
