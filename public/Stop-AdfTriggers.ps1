<#
.SYNOPSIS
Stops all triggers in Azure Data Factory instance (service).

.DESCRIPTION
Stops (disables) all triggers in Azure Data Factory instance (service).

.PARAMETER FactoryName
Name of Azure Data Factory service to be affected.

.PARAMETER ResourceGroupName
Resource Group Name of ADF service to be affected.

.EXAMPLE
$ResourceGroupName = 'rg-devops-factory'
$DataFactoryName = "SQLPlayerDemo"
Stop-AdfTriggers -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"

.LINK
Online version: https://github.com/SQLPlayer/azure.datafactory.tools/
#>
function Stop-AdfTriggers {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [String] $FactoryName,
        [parameter(Mandatory = $true)] [String] $ResourceGroupName
    )

    [Adf] $adf = New-Object 'Adf'
    $adf.Name = $FactoryName
    $adf.ResourceGroupName = $ResourceGroupName

    Stop-Triggers -adf $adf
    
}
