function Get-AdfObjectByName {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adf,
        [parameter(Mandatory = $true)] [String] $name
    )
    
    Write-Debug "BEGIN: Get-AdfObjectByName(name=$name)"
    # if ($null -eq $adf) { Write-Verbose "Variable [adf] is null." } else { Write-Verbose "[adf] is ok." }
    # Write-Verbose "ADF:"
    # Write-Verbose ($adf | Format-List | Out-String)
    # Write-Verbose "-----"

    $r = $adf.AllObjects() | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    # Write-Verbose "---R:"
    Write-Debug ($r | Format-List | Out-String)
    # Write-Verbose "-----"
    Write-Debug "END: Get-AdfObjectByName()"
    return $r
}
