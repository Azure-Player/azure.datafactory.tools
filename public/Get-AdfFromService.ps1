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

    $adfi = Get-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName"
    Write-Host ("Azure Data Factory (instance) loaded." -f $adf.DataSets.Count)
    $adf.Id = $adfi.DataFactoryId
    $adf.Location = $adfi.Location

    $adf.DataSets = Get-AzDataFactoryV2Dataset -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" | ToArray
    Write-Host ("DataSets: {0} object(s) loaded." -f $adf.DataSets.Count)
    $adf.IntegrationRuntimes = Get-AzDataFactoryV2IntegrationRuntime -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" | ToArray
    Write-Host ("IntegrationRuntimes: {0} object(s) loaded." -f $adf.IntegrationRuntimes.Count)
    $adf.LinkedServices = Get-AzDataFactoryV2LinkedService -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" | ToArray
    Write-Host ("LinkedServices: {0} object(s) loaded." -f $adf.LinkedServices.Count)
    $adf.Pipelines = Get-AzDataFactoryV2Pipeline -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" | ToArray
    Write-Host ("Pipelines: {0} object(s) loaded." -f $adf.Pipelines.Count)
    $adf.DataFlows = Get-AzDataFactoryV2DataFlow -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" | ToArray
    Write-Host ("DataFlows: {0} object(s) loaded." -f $adf.DataFlows.Count)
    $adf.Triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" | ToArray
    Write-Host ("Triggers: {0} object(s) loaded." -f $adf.Triggers.Count)

    Write-Debug "END: Get-AdfFromService()"
    return $adf
}
