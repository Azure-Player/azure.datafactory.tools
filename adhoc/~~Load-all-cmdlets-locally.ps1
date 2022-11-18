# Load-all-cmdlets-locally

$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'

Remove-Module 'azure.datafactory.tools' -ErrorAction SilentlyContinue
Get-Module 'az*'

#$PSScriptRoot = Get-Location   
$loc = '.'  #"x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\"
Write-Host "Loading cmdlets from private folder..."
if (Test-Path -Path "$loc\private" -ErrorAction Ignore)
{
    Write-Host (Resolve-Path "$loc\private")
    Get-ChildItem "$loc\private" -ErrorAction Stop | Where-Object { $_.Extension -eq '.ps1' } | ForEach-Object {
        Write-Verbose "Importing cmdlet '$($_.Name)'."
        . $_.FullName
    }
}

Write-Host "Loading cmdlets from public folder..."
if (Test-Path -Path "$loc\public" -ErrorAction Ignore)
{
    Write-Host (Resolve-Path "$loc\public")
    Get-ChildItem "$loc\public" -ErrorAction Stop | Where-Object { $_.Extension -eq '.ps1' } | ForEach-Object {
        Write-Verbose "Importing cmdlet '$($_.Name)'."
        . $_.FullName
    }
}




# Debug ON
$DebugPreference = "Continue"

# Debug OFF
$DebugPreference = "SilentlyContinue"
