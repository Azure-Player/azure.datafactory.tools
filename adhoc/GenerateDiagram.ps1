$folder = '****\DataFactory'
Import-Module 'azure.datafactory.tools'

$adf = Import-AdfFromFolder -FactoryName 'a' -RootFolder $folder

Clear-Host
$diag = ""
$line = "::: mermaid`ngraph TD`n"
$diag += $line
Write-Host $line

$adf.AllObjects() | ForEach-Object {
    $o = $_
    foreach ($d in $o.DependsOn) {
        $n1 = $o.FullName().Replace(' ', '_')
        $n2 = $d.Replace(' ', '_')
        $n2 = $n2.ToLower()[0] + $n2.Substring(1)
        $line = "$n1 --> $n2"
        Write-Host $line
        $diag += $line + "`n"
    }
}
$line = ":::"
$diag += $line + "`n"
Write-Host $line
$diag | Set-Content -Path 'diagram.md'

#----------------------------------------------------
Remove-Module 'azure.datafactory.tools'
Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module 'az*'

$RootFolder = '****\DataFactory'
$adf = Import-AdfFromFolder -FactoryName 'a' -RootFolder $RootFolder

Clear-Host
Get-AdfDocDiagram -adf $adf 

Get-AdfDocDiagram -adf $adf | Set-Content -Path 'diagram1.md'


$RootFolder = ".\test\BigFactorySample2"
$adf = Import-AdfFromFolder -RootFolder $RootFolder -FactoryName 'whatever'

# Execute the following command to generate diagram as MarkDown text code 
Get-AdfDocDiagram -adf $adf 

# You can change direction of output diagram:
Get-AdfDocDiagram -adf $adf -direction 'TD'

# Write output diagram to file:
Get-AdfDocDiagram -adf $adf | Set-Content -Path 'adf-diagram.md'

Set-AzContext -Subscription