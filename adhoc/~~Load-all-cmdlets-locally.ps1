# Load-all-cmdlets-locally

$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'

Remove-Module 'azure.datafactory.tools' -ErrorAction SilentlyContinue
Get-Module 'az*'

#$PSScriptRoot = Get-Location   
$loc = "x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\"
if (Test-Path -Path "$loc\private" -ErrorAction Ignore)
{
    Get-ChildItem "$loc\private" -ErrorAction Stop | Where-Object { $_.Extension -eq '.ps1' } | ForEach-Object {
        Write-Verbose "Importing cmdlet '$($_.Name)'."
        . $_.FullName
    }
}

if (Test-Path -Path "$loc\public" -ErrorAction Ignore)
{
    Get-ChildItem "$loc\public" -ErrorAction Stop | Where-Object { $_.Extension -eq '.ps1' } | ForEach-Object {
        Write-Verbose "Importing cmdlet '$($_.Name)'."
        . $_.FullName
    }
}




# Debug ON
$DebugPreference = "Continue"

# Debug OFF
$DebugPreference = "SilentlyContinue"
