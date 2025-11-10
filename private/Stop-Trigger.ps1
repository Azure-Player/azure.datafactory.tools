function Stop-Trigger {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [parameter(Mandatory = $true)] [string] $DataFactoryName,
        [parameter(Mandatory = $true)] [string] $Name
    )

    Write-host "- Disabling trigger: $Name" 
    try{
        Stop-AzDataFactoryV2Trigger `
        -ResourceGroupName $ResourceGroupName `
        -DataFactoryName $DataFactoryName `
        -Name $Name `
        -Force | Out-Null
    }
    catch{
        Write-Verbose $_.Exception
    }
}
