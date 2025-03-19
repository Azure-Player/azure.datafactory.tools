#
# Script module for module 'Azure.DataFactory.Tools' that is executed when 'Azure.DataFactory.Tools' is imported in a PowerShell session.
#

$PSDefaultParameterValues.Clear()
Set-StrictMode -Version Latest


if ($true -and ($PSEdition -eq 'Desktop'))
{
    if ($PSVersionTable.PSVersion -lt [Version]'5.1')
    {
        throw "PowerShell versions lower than 5.1 are not supported in Az. Please upgrade to PowerShell 5.1 or higher."
    }
}

if (Test-Path -Path "$PSScriptRoot\private" -ErrorAction Ignore)
{
    Get-ChildItem "$PSScriptRoot\private" -ErrorAction Stop | Where-Object { $_.Extension -eq '.ps1' } | ForEach-Object {
        Write-Verbose "Importing cmdlet '$($_.Name)'."
        . $_.FullName
    }
}

if (Test-Path -Path "$PSScriptRoot\public" -ErrorAction Ignore)
{
    Get-ChildItem "$PSScriptRoot\public" -ErrorAction Stop | Where-Object { $_.Extension -eq '.ps1' } | ForEach-Object {
        Write-Verbose "Importing cmdlet '$($_.Name)'."
        . $_.FullName
    }
}

$script:BaseApiUrl = "https://management.azure.com"
$moduleName = 'Az.DataFactory'
$module = Get-Module $moduleName
$minVer = "1.10.0"
if ($null -ne $module -and $module.Version -lt [System.Version]$minVer) 
{ 
    Write-Error "This module requires $moduleName version $minVer. An earlier version of $moduleName is imported in the current PowerShell session. Please open a new session before importing this module. This error could indicate that multiple incompatible versions of the Azure PowerShell cmdlets are installed on your system. Please see https://aka.ms/azps-version-error for troubleshooting information." -ErrorAction Stop 
} 
elseif ($null -eq $module) 
{
    Write-Host "Importing module $moduleName (> $minVer)..."
    Import-Module -Name $moduleName -MinimumVersion "$minVer" -Scope Global
    $module = Get-Module $moduleName
    Write-Host "Module $ModuleName (v.$($module.Version)) imported."
}
