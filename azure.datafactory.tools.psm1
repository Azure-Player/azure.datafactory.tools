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

$module = Get-Module Az.DataFactory
$minVer = "1.7.0"
if ($null -ne $module -and $module.Version.ToString().CompareTo($minVer) -lt 0) 
{ 
    Write-Error "This module requires Az.DataFactory version $minVer. An earlier version of Az.DataFactory is imported in the current PowerShell session. Please open a new session before importing this module. This error could indicate that multiple incompatible versions of the Azure PowerShell cmdlets are installed on your system. Please see https://aka.ms/azps-version-error for troubleshooting information." -ErrorAction Stop 
} 
elseif ($null -eq $module) 
{ 
    Import-Module Az.DataFactory -MinimumVersion "$minVer" -Scope Global
}
