function ConvertTo-AdfType {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] 
        [String] $AzType
    )

    $resType = ""

    switch -Exact ($AzType)
    {
        'Microsoft.DataFactory/factories/integrationruntimes'    { $resType = 'integrationRuntime' }
        'Microsoft.DataFactory/factories/pipelines'              { $resType = 'pipeline' }
        'Microsoft.DataFactory/factories/datasets'               { $resType = 'dataset' }
        'Microsoft.DataFactory/factories/dataflows'              { $resType = 'dataflow' }
        'Microsoft.DataFactory/factories/linkedservices'         { $resType = 'linkedService' }
        'Microsoft.DataFactory/factories/triggers'               { $resType = 'trigger' }
        'Microsoft.DataFactory/factories/credentials'            { $resType = 'credential' }
        'Microsoft.DataFactory/factories/managedVirtualNetworks' { $resType = 'managedVirtualNetwork' }
        'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints' { $resType = 'managedVirtualNetwork\default\managedPrivateEndpoint' }
        'Microsoft.DataFactory/factories'               { $resType = 'factory' }
        default                 { Write-Error "ADFT0030: AzType '$AzType' is not supported." }
    }

    return $resType
}