<#

.Change History
Changed to write out DDL to import into SQL Temp Table for easier querying of dependecies.  Idea from "No more breaking changes! Get insights in your platform dependencies" by Rohan Horstman @ Data Grillen / @New Stars of Data on 07/10/22

.SYNOPSIS
Generates SQL Statement of dependencies between ADF objects which can be used to import into temp table and search for source or target easier.

.DESCRIPTION
Generates DDL of dependencies between ADF objects.

.PARAMETER adf
Object of adf class represents all adf objects from code.

.PARAMETER direction
Diagram direction: LR - Left to Right (default), TD - Top to Down

.EXAMPLE
$RootFolder = "c:\GitHub\AdfName\"
$adf = Import-AdfFromFolder -RootFolder $RootFolder -FactoryName 'whatever'
Get-AdfDocDiagram -adf $adf 

.EXAMPLE
Get-AdfDocDiagram -adf $adf -direction 'TD'

.EXAMPLE
Get-AdfDocDiagram -adf $adf | Set-Content -Path 'adf-diagram.sql'

.LINK
Online version: https://github.com/SQLPlayer/azure.datafactory.tools/
#>
function Get-AdfDocDiagram {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)] 
        [Adf] $adf,

        [ValidateSet("LR", "TD")]
        [String] $direction = 'LR'
    )
    Write-Debug "BEGIN: Get-AdfDocDiagram(adf=$adf, direction=$direction)"

    $diag = ""
    $line = "DROP TABLE IF EXISTS #Dependency`n"
	$line2 = "CREATE TABLE #Dependency(Source nvarchar(max), Target nvarchar(max))`n"
    $diag += $line += $line2
    
    $adf.AllObjects() | ForEach-Object {
        $o = $_
        foreach ($d in $o.DependsOn) {
            $n1 = $o.FullName().Replace(' ', '_')
            $n2 = $d.Replace(' ', '_')
            $n2 = $n2.ToLower()[0] + $n2.Substring(1)
            $line = "INSERT INTO #Dependency(Source,Target) VALUES ('$n1','$n2');"
            $diag += $line + "`n"
        }
    }
    $diag += "--Staging Table #Dependency filled"
    
    Write-Debug "END: Get-AdfDocDiagram()"
    return $diag
}
