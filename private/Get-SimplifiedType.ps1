function Get-SimplifiedType {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [String] $Type
    )

    $simtype = $type
    if ($type -like 'PS*') { $simtype = $type.Substring(2) }
    if ($simtype -like '*IntegrationRuntime') { $simtype = 'IntegrationRuntime' }
    if ($simtype -like '*managedPrivateEndpoint') { $simtype = 'managedPrivateEndpoint' }

    #Write-Debug "Get-SimplifiedType($Type) = $simtype"
    return $simtype
}