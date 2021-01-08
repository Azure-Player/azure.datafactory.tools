<#
.SYNOPSIS
Reads all ADF objects (JSON files) from pointed location and returns instance of [ADF] class.

.DESCRIPTION
Reads all ADF objects (JSON files) from pointed location and returns instance of [ADF] class.

.PARAMETER FactoryName
Gives the name for created object of ADF

.PARAMETER RootFolder
Location where all folders and JSON files are kept.

.EXAMPLE
$adf = Import-AdfFromFolder -FactoryName "AdfSQLPlayerDemo" -RootFolder "c:\GitHub\AdfName\"
IntegrationRuntimes: 4 object(s) loaded.
LinkedServices: 9 object(s) loaded.
Pipelines: 12 object(s) loaded.
DataSets: 26 object(s) loaded.
DataFlows: 7 object(s) loaded.
Triggers: 3 object(s) loaded.

.NOTES
Online version: https://github.com/SQLPlayer/azure.datafactory.tools/
#>
function Import-AdfFromFolder {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [String] $FactoryName,
        [parameter(Mandatory = $true)] [String] $RootFolder
    )
    Write-Debug "BEGIN: Import-AdfFromFolder(FactoryName=$FactoryName, RootFolder=$RootFolder)"

    Write-Verbose "Analyzing files of Azure Data Factory..."
    $adf = New-Object -TypeName Adf 
    $adf.Name = $FactoryName

    if ( !(Test-Path -Path $RootFolder) ) { Write-Error "ADFT0019: Folder '$RootFolder' doesn't exist." }
    
    $adf.Location = $RootFolder

    Import-AdfObjects -Adf $adf -All $adf.IntegrationRuntimes -RootFolder $RootFolder -SubFolder "integrationRuntime" | Out-Null
    Write-Host ("IntegrationRuntimes: {0} object(s) loaded." -f $adf.IntegrationRuntimes.Count)
    Import-AdfObjects -Adf $adf -All $adf.LinkedServices -RootFolder $RootFolder -SubFolder "linkedService" | Out-Null
    Write-Host ("LinkedServices: {0} object(s) loaded." -f $adf.LinkedServices.Count)
    Import-AdfObjects -Adf $adf -All $adf.Pipelines -RootFolder $RootFolder -SubFolder "pipeline" | Out-Null
    Write-Host ("Pipelines: {0} object(s) loaded." -f $adf.Pipelines.Count)
    Import-AdfObjects -Adf $adf -All $adf.DataSets -RootFolder $RootFolder -SubFolder "dataset" | Out-Null
    Write-Host ("DataSets: {0} object(s) loaded." -f $adf.DataSets.Count)
    Import-AdfObjects -Adf $adf -All $adf.DataFlows -RootFolder $RootFolder -SubFolder "dataflow" | Out-Null
    Write-Host ("DataFlows: {0} object(s) loaded." -f $adf.DataFlows.Count)
    Import-AdfObjects -Adf $adf -All $adf.Triggers -RootFolder $RootFolder -SubFolder "trigger" | Out-Null
    Write-Host ("Triggers: {0} object(s) loaded." -f $adf.Triggers.Count)
    Import-AdfObjects -Adf $adf -All $adf.Factories -RootFolder $RootFolder -SubFolder "factory" | Out-Null
    Write-Host ("Factories: {0} object(s) loaded." -f $adf.Factories.Count)

    Write-Debug "END: Import-AdfFromFolder()"
    return $adf
}
