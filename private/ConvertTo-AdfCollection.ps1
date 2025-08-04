function ConvertTo-AdfCollection {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] 
        [String] $AzType
    )

    $resType = ""

    switch -Exact ($AzType)
    {
        'Microsoft.DataFactory/factories/pipelines'                                      { $resType = 'Pipelines' }
        'Microsoft.DataFactory/factories/linkedservices'                                 { $resType = 'LinkedServices' }
        'Microsoft.DataFactory/factories/datasets'                                       { $resType = 'Datasets' }
        'Microsoft.DataFactory/factories/dataflows'                                      { $resType = 'Dataflows' }
        'Microsoft.DataFactory/factories/triggers'                                       { $resType = 'Triggers' }
        'Microsoft.DataFactory/factories/integrationruntimes'                            { $resType = 'IntegrationRuntimes' }
        'Microsoft.DataFactory/factories'                                                { $resType = 'Factories' }
        'Microsoft.DataFactory/factories/managedVirtualNetworks'                         { $resType = 'ManagedVirtualNetworks' }
        'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints' { $resType = 'ManagedPrivateEndpoints' }
        'Microsoft.DataFactory/factories/credentials'                                    { $resType = 'Credentials' }
        default                                                                          { Write-Error "ADFT0030: AzType '$AzType' is not supported." }
    }

    return $resType
}