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

    Test-Path -Path $RootFolder | Out-Null 
    $adf.Location = $RootFolder

    Import-AdfObjects -Adf $adf -All $adf.IntegrationRuntimes -RootFolder $RootFolder -SubFolder "integrationRuntime" | Out-Null
    Write-Host ("IntegrationRuntimes: {0} object(s) loaded." -f $adf.IntegrationRuntimes.Count)
    Import-AdfObjects -Adf $adf -All $adf.LinkedServices -RootFolder $RootFolder -SubFolder "LinkedService" | Out-Null
    Write-Host ("LinkedServices: {0} object(s) loaded." -f $adf.LinkedServices.Count)
    Import-AdfObjects -Adf $adf -All $adf.Pipelines -RootFolder $RootFolder -SubFolder "pipeline" | Out-Null
    Write-Host ("Pipelines: {0} object(s) loaded." -f $adf.Pipelines.Count)
    Import-AdfObjects -Adf $adf -All $adf.DataSets -RootFolder $RootFolder -SubFolder "dataset" | Out-Null
    Write-Host ("DataSets: {0} object(s) loaded." -f $adf.DataSets.Count)
    Import-AdfObjects -Adf $adf -All $adf.DataFlows -RootFolder $RootFolder -SubFolder "dataflow" | Out-Null
    Write-Host ("DataFlows: {0} object(s) loaded." -f $adf.DataFlows.Count)
    Import-AdfObjects -Adf $adf -All $adf.Triggers -RootFolder $RootFolder -SubFolder "trigger" | Out-Null
    Write-Host ("Triggers: {0} object(s) loaded." -f $adf.Triggers.Count)

    Write-Debug "END: Import-AdfFromFolder()"
    return $adf
}
