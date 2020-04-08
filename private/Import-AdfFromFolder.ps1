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

    Import-AdfObjects -Adf $adf -All $adf.LinkedServices -RootFolder $RootFolder -SubFolder "LinkedService" -AzureType "Microsoft.DataFactory/factories/linkedservices" | Out-Null
    Write-Verbose ("LinkedServices: {0} object(s) loaded." -f $adf.LinkedServices.Count)
    Import-AdfObjects -Adf $adf -All $adf.Pipelines -RootFolder $RootFolder -SubFolder "pipeline" -AzureType "Microsoft.DataFactory/factories/pipelines" | Out-Null
    Write-Verbose ("Pipelines: {0} object(s) loaded." -f $adf.Pipelines.Count)
    Import-AdfObjects -Adf $adf -All $adf.DataSets -RootFolder $RootFolder -SubFolder "dataset" -AzureType "Microsoft.DataFactory/factories/datasets" | Out-Null
    Write-Verbose ("DataSets: {0} object(s) loaded." -f $adf.DataSets.Count)

    Write-Debug "END: Import-AdfFromFolder()"
    return $adf
}
