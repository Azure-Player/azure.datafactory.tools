<#
.SYNOPSIS
Starts all triggers in Azure Data Factory instance (service).

.DESCRIPTION
Starts (disables) all triggers in Azure Data Factory instance (service).

.PARAMETER adf
Object of adf class which contains info about target adf and its triggers

.EXAMPLE
$ResourceGroupName = 'rg-devops-factory'
$DataFactoryName = "SQLPlayerDemo"
Start-AdfTriggers -adf $adf -ResourceGroupName "$ResourceGroupName"

.LINK
Online version: https://github.com/SQLPlayer/azure.datafactory.tools/
#>
function Start-AdfTriggers {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adf
    )

    if (!$adf.PublishOptions) {
        $adf.PublishOptions = New-AdfPublishOption
    }
    Start-Triggers -adf $adf
    
}
