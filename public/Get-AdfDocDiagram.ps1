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
        [String] $direction = 'LR',

        [Array] $exclude = $null, 
        [Array] $include = $null
    )
    Write-Debug "BEGIN: Get-AdfDocDiagram(adf=$adf, direction=$direction)"

    $diag = ""
    $line = "::: mermaid`ngraph $direction`n"
    $diag += $line
    
    $adf.AllObjects() | ForEach-Object {
        $o = $_
        $n1 = $o.FullName().Replace(' ', '_')
        Write-Verbose "Analyse: $($o.FullName())"
        foreach ($d in $o.DependsOn) {
            $n2 = $d.Replace(' ', '_')
            $n2 = $n2.ToLower()[0] + $n2.Substring(1)
            Write-Verbose "- $d"
            $show = $true
            if ($include) {
                 $show = ($include | ForEach-Object { if ($n1 -ilike $_ -or $n2 -ilike $_) {1} else {0} } | Measure-Object -Maximum).Maximum -gt 0
            } else 
            {
                 $show = -not ($exclude | ForEach-Object { if ($n1 -ilike $_ -or $n2 -ilike $_) {1} else {0} } | Measure-Object -Maximum).Maximum -gt 0
            }
            if ($show) {
              $line = "$n1 --> $n2"
              $diag += $line + "`n"
            } else {
                Write-Verbose "$d - excluded."
            }
        }
    }
    $diag += ":::"
    
    Write-Debug "END: Get-AdfDocDiagram()"
    return $diag
}
