function Start-Trigger {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [parameter(Mandatory = $true)] [string] $DataFactoryName,
        [parameter(Mandatory = $true)] [string] $Name
    )
    Write-Debug "BEGIN: Start-Trigger()"

    Write-Host "- Enabling trigger: $Name"
    $attempts = 5;
    $i = 0
    while ($i -lt $attempts)
    {
        $i++
        try {
            Start-AzDataFactoryV2Trigger `
                -ResourceGroupName $ResourceGroupName `
                -DataFactoryName $DataFactoryName `
                -Name $Name `
                -Force | Out-Null
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
                    Write-Verbose "Attempt #$i of starting trigger failed. Retry in 2 seconds."
                    Start-Sleep -Seconds 2
                }
            }
            else
            {
                Write-Host "Failed starting trigger after $attempts attempts."
                Write-Warning -Message $errMsg
            }
        }
    }

    Write-Debug "END: Start-Trigger()"
}
