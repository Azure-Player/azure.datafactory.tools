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
        }
        catch {
            if ($i -lt $attempts)
            {
                Write-Verbose "Attempt #$i of starting trigger failed. Retry in 2 seconds."
                Start-Sleep -Seconds 2 
            } 
            else 
            {
                Write-Host "Failed starting trigger after $attempts attempts."
                Write-Warning -Message $_.Exception.Message
            }
        }
    }

    Write-Debug "END: Start-Trigger()"
}
