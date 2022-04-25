Clear-Host

$modules = 'azure.datafactory.tools'
$modules = 'Az.Accounts', 'az.resources', 'az.datafactory', 'azure.datafactory.tools'
$modules = 'az.datafactory'
$modules = 'az.resources'
$modules = 'az.Accounts'

Remove-Module -Name $modules
Get-Module $modules -ListAvailable

UnInstall-Module Az.DataFactory -RequiredVersion 1.8.0
#Import-Module azure.datafactory.tools -RequiredVersion 1.8.2
Update-Module $modules -Scope CurrentUser -Force
Import-Module $modules
Get-Module $modules

Update-Module azure.datafactory.tools -RequiredVersion 0.19.0
Get-Module azure.datafactory.tools -ListAvailable

# Import module from local code
Import-Module .\azure.datafactory.tools.psd1 -Force
Save-Module -Name 'Az.Accounts' -Path 'd:\temp' 
Save-Module -Name 'Az.datafactory' -Path 'd:\temp'



Get-Module 'az.*' -ListAvailable

# [Agent Windows 2016](https://github.com/actions/virtual-environments/blob/main/images/win/Windows2016-Readme.md)
# [Az 4.7](https://www.powershellgallery.com/packages/Az/4.7.0)
# Contains Az.DataFactory (= 1.10.1)

# [Agent: Microsoft Windows Server 2019 Datacenter](https://github.com/actions/virtual-environments/blob/main/images/win/Windows2019-Readme.md)
# [Az 4.7](https://www.powershellgallery.com/packages/Az/4.7.0)
# Contains Az.DataFactory (= 1.10.1)


Update-Help 'azure.datafactory.tools'
Update-Help 'azure.datafactory.tools' -UICulture en-US


Import-Module azure.datafactory.tools
Get-Module -ListAvailable | ? { $_.HelpInfoUri -like 'https:*' }

