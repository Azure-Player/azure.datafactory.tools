function Get-AzureResourceType {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] 
        [String] $Type
    )

    $resType = ""
    if ($type -like 'PS*') { $type = $type.Substring(2) }
    if ($type -like '*IntegrationRuntime') { $type = 'IntegrationRuntime' }

    switch -Exact ($type)
    {
        'integrationRuntime'    { $resType = 'Microsoft.DataFactory/factories/integrationruntimes' }
        'pipeline'              { $resType = 'Microsoft.DataFactory/factories/pipelines' }
        'dataset'               { $resType = 'Microsoft.DataFactory/factories/datasets' }
        'dataflow'              { $resType = 'Microsoft.DataFactory/factories/dataflows' }
        'linkedService'         { $resType = 'Microsoft.DataFactory/factories/linkedservices' }
        'trigger'               { $resType = 'Microsoft.DataFactory/factories/triggers' }
        'managedVirtualNetwork' { $resType = 'Microsoft.DataFactory/factories/managedVirtualNetworks' }
        'managedVirtualNetwork\default\managedPrivateEndpoint' { $resType = 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints' }
        'factory'               { $resType = 'Microsoft.DataFactory/factories' }
        'credential'            { $resType = 'Microsoft.DataFactory/factories/credentials' }
        default                 { Write-Error "ADFT0016: Type '$Type' is not supported." }
    }

    return $resType
}