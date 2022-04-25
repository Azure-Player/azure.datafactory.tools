Update-Help -Module 'azure.datafactory.tools'

Update-Help -Module 'Microsoft.PowerShell.Utility'
Update-Help -Module 'Microsoft.PowerShell.Security'


Install-Module 'PSReadline'

Get-Help 'Publish-AdfV2FromJson' -Full
Get-Help 'Export-AdfToArmTemplate'

Update-Help -SourcePath 'D:\azure.datafactory.tools\azure.datafactory.tools.psd1'
Update-Help -SourcePath "c:\Program Files\PowerShell\7\Modules\PSReadLine\PSReadLine.psd1" 


$DebugPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
Get-Module
Remove-Module 'azure.datafactory.tools'
Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module
Update-Help 'azure.datafactory.tools', "DbaTools", 'PSReadline', 'DatabricksPS'

Import-Module "DbaTools" -Force
Update-Help  

$m = 'azure.databricks.cicd.tools'
$m = 'DatabricksPS'

Install-Module "$m" -Scope CurrentUser -Force -AllowClobber
Import-Module "$m" -Force
Update-Help  "$m"



