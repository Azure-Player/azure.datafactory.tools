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
        $triggerNames = $adf.Triggers | ForEach-Object {$_.name}
        #$deletedTriggers = $triggersADF | Where-Object { $triggerNames -notcontains $_.Name }
        $triggersToStop = $triggerNames | Where-Object { ($triggersADF | Select-Object name).name -contains $_ }
        Write-Verbose ("Triggers to stop: " + $triggersToStop.Count)

        #Stop all triggers
        Write-Host "Stopping deployed triggers:"
        $triggersToStop | ForEach-Object { 
            Write-host "- Disabling trigger: " $_
            Stop-AzDataFactoryV2Trigger `
            -ResourceGroupName $adf.ResourceGroupName `
            -DataFactoryName $adf.Name `
            -Name $_ `
            -Force | Out-Null
        }
        Write-Host "Complete stopping deployed triggers"
    }

    Write-Debug "END: Stop-Triggers()"
}
