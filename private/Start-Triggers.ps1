function Start-Triggers {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adf
    )
    Write-Debug "BEGIN: Start-Triggers()"

    [AdfObject[]] $activeTrigger = $adf.Triggers `
    | Where-Object { $_.Body.properties.runtimeState -eq "Started" } | ToArray
    Write-Host ("The number of triggers to start: " + $activeTrigger.Count)

    #Start active triggers - after cleanup efforts
    $activeTrigger | ForEach-Object { 
        Write-Host "- Enabling trigger: $($_.Name)"
        [AdfObjectName] $oname = [AdfObjectName]::new("trigger.$($_.Name)")
        $IsMatchExcluded = $oname.IsNameExcluded($adf.PublishOptions)
        if ($IsMatchExcluded -and $adf.PublishOptions.DoNotStopStartExcludedTriggers) {
            Write-host "- Excluded trigger: $($_.Name)" 
        } else {
            try {
                Start-AzDataFactoryV2Trigger `
                    -ResourceGroupName $adf.ResourceGroupName `
                    -DataFactoryName $adf.Name `
                    -Name $_.Name `
                    -Force | Out-Null
            }
            catch {
                Write-Host "Failed starting trigger."
                Write-Warning -Message $_.Exception.Message
            }
        }
    }

    Write-Debug "END: Start-Triggers()"
}
