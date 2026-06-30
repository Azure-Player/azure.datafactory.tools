<#
.SYNOPSIS
Loads all objects from Azure Data Factory instance (service).

.DESCRIPTION
Loads all objects from Azure Data Factory instance (service).

.PARAMETER FactoryName
Name of Azure Data Factory service to be loaded.

.PARAMETER ResourceGroupName
Resource Group Name of ADF service to be loaded.

.EXAMPLE
$ResourceGroupName = 'rg-devops-factory'
$DataFactoryName = "SQLPlayerDemo"
$adfIns = Get-AdfFromService -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
$adfIns.AllObjects()

.LINK
Online version: https://github.com/SQLPlayer/azure.datafactory.tools/
#>
function Get-AdfFromService {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [String] $FactoryName,
        [parameter(Mandatory = $true)] [String] $ResourceGroupName
    )
    Write-Debug "BEGIN: Get-AdfFromService(FactoryName=$FactoryName, ResourceGroupName=$ResourceGroupName)"

    $adf = New-Object -TypeName AdfInstance
    $adf.Name = $FactoryName
    $adf.ResourceGroupName = $ResourceGroupName

    $adfi = Get-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$FactoryName"
    Write-Host "Azure Data Factory (instance) loaded."
    $adf.Id = $adfi.DataFactoryId
    $adf.Location = $adfi.Location

    try {
        $adf.DataSets = Get-AzDataFactoryV2Dataset -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$FactoryName" -ErrorAction Stop | ToArray
    } catch {
        Write-Warning "Failed to list Datasets via Az cmdlet (possible deserialization issue). Falling back to REST API. Error: $_"
        $adf.DataSets = Get-AdfObjectsFromServiceRestAPI -adfi $adfi -typePlural 'datasets' -simpleType 'Dataset' | ToArray
    }
    Write-Host ("DataSets: {0} object(s) loaded." -f $adf.DataSets.Count)
    try {
        $adf.IntegrationRuntimes = Get-AzDataFactoryV2IntegrationRuntime -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$FactoryName" -ErrorAction Stop | ToArray
    } catch {
        Write-Warning "Failed to list IntegrationRuntimes via Az cmdlet (possible deserialization issue). Falling back to REST API. Error: $_"
        $adf.IntegrationRuntimes = Get-AdfObjectsFromServiceRestAPI -adfi $adfi -typePlural 'integrationruntimes' -simpleType 'IntegrationRuntime' | ToArray
    }
    Write-Host ("IntegrationRuntimes: {0} object(s) loaded." -f $adf.IntegrationRuntimes.Count)
    try {
        $adf.LinkedServices = Get-AzDataFactoryV2LinkedService -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$FactoryName" -ErrorAction Stop | ToArray
    } catch {
        Write-Warning "Failed to list LinkedServices via Az cmdlet (possible deserialization issue). Falling back to REST API. Error: $_"
        $adf.LinkedServices = Get-AdfObjectsFromServiceRestAPI -adfi $adfi -typePlural 'linkedservices' -simpleType 'LinkedService' | ToArray
    }
    Write-Host ("LinkedServices: {0} object(s) loaded." -f $adf.LinkedServices.Count)
    try {
        $adf.Pipelines = Get-AzDataFactoryV2Pipeline -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$FactoryName" -ErrorAction Stop | ToArray
    } catch {
        Write-Warning "Failed to list Pipelines via Az cmdlet (possible deserialization issue). Falling back to REST API. Error: $_"
        $adf.Pipelines = Get-AdfObjectsFromServiceRestAPI -adfi $adfi -typePlural 'pipelines' -simpleType 'Pipeline' | ToArray
    }
    Write-Host ("Pipelines: {0} object(s) loaded." -f $adf.Pipelines.Count)
    try {
        $adf.DataFlows = Get-AzDataFactoryV2DataFlow -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$FactoryName" -ErrorAction Stop | ToArray
    } catch {
        Write-Warning "Failed to list DataFlows via Az cmdlet (possible deserialization issue). Falling back to REST API. Error: $_"
        $adf.DataFlows = Get-AdfObjectsFromServiceRestAPI -adfi $adfi -typePlural 'dataflows' -simpleType 'DataFlow' | ToArray
    }
    Write-Host ("DataFlows: {0} object(s) loaded." -f $adf.DataFlows.Count)
    try {
        $adf.Triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$FactoryName" -ErrorAction Stop | ToArray
    } catch {
        Write-Warning "Failed to list Triggers via Az cmdlet (possible deserialization issue). Falling back to REST API. Error: $_"
        $adf.Triggers = Get-AdfObjectsFromServiceRestAPI -adfi $adfi -typePlural 'triggers' -simpleType 'Trigger' | ToArray
    }
    Write-Host ("Triggers: {0} object(s) loaded." -f $adf.Triggers.Count)
    $adf.Credentials = Get-AzDFV2Credential -adfi $adfi | ToArray
    Write-Host ("Credentials: {0} object(s) loaded." -f $adf.Credentials.Count)

    Write-Debug "END: Get-AdfFromService()"
    return $adf
}
