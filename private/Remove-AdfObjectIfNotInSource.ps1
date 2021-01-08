function Remove-AdfObjectIfNotInSource {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adfSource,
        [parameter(Mandatory = $true)] $adfTargetObj,
        [parameter(Mandatory = $true)] $adfInstance
    )
    
    Write-Debug "BEGIN: Get-AdfObjectIfNotInSource()"
    
    $name = $adfTargetObj.Name
    $type = $adfTargetObj.GetType().Name
    $simtype = Get-SimplifiedType -Type "$type"
    $src = Get-AdfObjectByName -adf $adfSource -name $name -type $type
    if (!$src) 
    {
        Write-Verbose "Object [$simtype].[$name] hasn't been found in the source - to be deleted."
        Remove-AdfObject -adfSource $adfSource -obj $adfTargetObj -adfInstance $adfInstance
    }
    else {
        Write-Verbose "Object [$simtype].[$name] is in the source - won't be delete."
    }

    Write-Debug "END: Get-AdfObjectIfNotInSource()"
}
