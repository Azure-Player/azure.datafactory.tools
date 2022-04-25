# https://docs.microsoft.com/en-us/powershell/scripting/developer/module/writing-help-for-windows-powershell-modules?view=powershell-7
# https://docs.microsoft.com/en-us/powershell/scripting/developer/help/examples-of-comment-based-help?view=powershell-7

Get-Help -Path .\public\Publish-AdfV2FromJson.ps1

.\debug\~~Load-all-cmdlets-locally.ps1

Clear-Host
Get-Module -Name ("Az.DataFactory", "azure.datafactory.tools")
Get-Help -Name "Az.DataFactory"



Import-Module .\azure.datafactory.tools.psd1 -Force

Clear-Host
Get-Help -Name "azure.datafactory.tools"


Get-Help -Name Publish-AdfV2FromJson
Clear-Host
Get-Help -Name Publish-AdfV2FromJson -examples
Get-Help -Name Publish-AdfV2FromJson -Detailed
Get-Help -Name Publish-AdfV2FromJson -full

