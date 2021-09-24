<#
.SYNOPSIS
Generates mermaid diagram of dependencies between ADF objects.

.DESCRIPTION
Generates mermaid diagram of dependencies between ADF objects.

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
Get-AdfDocDiagram -adf $adf | Set-Content -Path 'adf-diagram.md'

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
    $line = "::: mermaid`ngraph $direction`n"
    $diag += $line
    
    $adf.AllObjects() | ForEach-Object {
        $o = $_
        foreach ($d in $o.DependsOn) {
            $n1 = $o.FullName().Replace(' ', '_')
            $n2 = $d.Replace(' ', '_')
            $n2 = $n2.ToLower()[0] + $n2.Substring(1)
            $line = "$n1 --> $n2"
            $diag += $line + "`n"
        }
    }
    $diag += ":::"
    
    Write-Debug "END: Get-AdfDocDiagram()"
    return $diag
}
