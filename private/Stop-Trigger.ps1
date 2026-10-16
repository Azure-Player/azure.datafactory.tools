function Stop-Trigger {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [parameter(Mandatory = $true)] [string] $DataFactoryName,
        [parameter(Mandatory = $true)] [string] $Name
    )
    Write-Debug "BEGIN: Stop-Trigger()"

    Write-Host "- Disabling trigger: $Name"
    $attempts = 5;
    $i = 0
    $stopped = $false
    while ($i -lt $attempts)
    {
        $i++
        try {
            # Az cmdlets write non-terminating errors, so -ErrorAction Stop is required to catch them
            Stop-AzDataFactoryV2Trigger `
                -ResourceGroupName $ResourceGroupName `
                -DataFactoryName $DataFactoryName `
                -Name $Name `
                -Force -ErrorAction Stop | Out-Null
            # If successful, break out of the loop
            $stopped = $true
            break
        }
        catch {
            $errMsg = $_.Exception.Message
            if ($i -lt $attempts)
            {
                if ($errMsg -like "*cannot be updated during provisioning*") {
                    Write-Verbose "Attempt #${i}: Trigger '$Name' is still provisioning. Waiting for provisioning to complete..."
                    $provisioningTimeout = 300
                    $pollInterval = 10
                    $elapsed = 0
                    while ($elapsed -lt $provisioningTimeout) {
                        Start-Sleep -Seconds $pollInterval
                        $elapsed += $pollInterval
                        $trigger = Get-AzDataFactoryV2Trigger `
                            -ResourceGroupName $ResourceGroupName `
                            -DataFactoryName $DataFactoryName `
                            -Name $Name
                        $provState = $trigger.Properties.ProvisioningState
                        Write-Verbose "Trigger provisioning state: $provState ($elapsed sec elapsed)"
                        if ($provState -ne 'Provisioning') { break }
                    }
                } else {
                    Write-Verbose "Attempt #$i of stopping trigger failed. Retry in 2 seconds."
                    Start-Sleep -Seconds 2
                }
            }
            else
            {
                Write-Host "Failed stopping trigger after $attempts attempts."
                Write-Warning -Message $errMsg
            }
        }
    }

    Write-Debug "END: Stop-Trigger()"
    return $stopped
}
