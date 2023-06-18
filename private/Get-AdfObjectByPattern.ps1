function Get-AdfObjectByPattern {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adf,
        [parameter(Mandatory = $true)] [String] $name,
        [parameter(Mandatory = $true)] [String] $type
    )
    
    Write-Debug "BEGIN: Get-AdfObjectByPattern(name=$name,type=$type)"

    $simtype = Get-SimplifiedType -Type "$type"
    $r = $null
    switch -Exact ($simtype)
    {
        'IntegrationRuntime'
        {
            $r = $adf.IntegrationRuntimes | Where-Object { $_.Name -like $name }
        }
        'LinkedService'
        {
            $r = $adf.LinkedServices | Where-Object { $_.Name -like $name } 
        }
        'Pipeline'
        {
            $r = $adf.Pipelines | Where-Object { $_.Name -like $name } 
        }
        'Dataset'
        {
            $r = $adf.DataSets | Where-Object { $_.Name -like $name }
        }
        'DataFlow'
        {
            $r = $adf.DataFlows | Where-Object { $_.Name -like $name } 
        }
        'Trigger'
        {
            $r = $adf.Triggers | Where-Object { $_.Name -like $name } 
        }
        'Factory'
        {
            $r = $adf.Factories | Where-Object { $_.Name -like $name }
        }
        'managedVirtualNetwork'
        {
            $r = $adf.ManagedVirtualNetwork | Where-Object { $_.Name -like $name }
        }
        'managedPrivateEndpoint'
        {
            $r = $adf.ManagedPrivateEndpoints | Where-Object { $_.Name -like $name }
        }
        'Credential'
        {
            $r = $adf.Credentials | Where-Object { $_.Name -like $name }
        }
        default
        {
            Write-Error "ADFT0015: Type [$type] is not supported."
        }
    }

    Write-Debug ($r | Format-List | Out-String)
    Write-Debug "END: Get-AdfObjectByPattern()"
    return $r
}
