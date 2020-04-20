function Start-Triggers {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adf
    )
    Write-Debug "BEGIN: Start-Triggers()"

    [AdfObject[]] $activeTrigger = $adf.Triggers `
    | Where-Object { $_.Body.properties.runtimeState -eq "Started" -and ($_.Body.properties.pipelines.count -gt 0)} | ToArray
    Write-Host ("The number of triggers to start: " + $activeTrigger.Count)

    #Start active triggers - after cleanup efforts
    $activeTrigger | ForEach-Object { 
        Write-host "- Enabling trigger: " $_
        Start-AzDataFactoryV2Trigger `
        -ResourceGroupName $adf.ResourceGroupName `
        -DataFactoryName $adf.Name `
        -Name $_.Name `
        -Force | Out-Null
    }

    Write-Debug "END: Start-Triggers()"
}
