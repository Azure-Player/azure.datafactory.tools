function Get-AdfObjectByName {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adf,
        [parameter(Mandatory = $true)] [String] $name,
        [parameter(Mandatory = $true)] [String] $type
    )
    
    Write-Debug "BEGIN: Get-AdfObjectByName(name=$name,type=$type)"

    $simtype = Get-SimplifiedType -Type "$type"
    switch -Exact ($simtype)
    {
        {$simtype -in [AdfObject]::IgnoreTypes}
        {
            $r = New-Object -TypeName AdfObject 
            $r.Name = "Ignored"
            $r.Type = $simtype
            $r.Adf = $adf
            Break
        }
        'IntegrationRuntime'
        {
            $r = $adf.IntegrationRuntimes | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'LinkedService'
        {
            $r = $adf.LinkedServices | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'Pipeline'
        {
            $r = $adf.Pipelines | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'Dataset'
        {
            $r = $adf.DataSets | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'DataFlow'
        {
            $r = $adf.DataFlows | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'Trigger'
        {
            $r = $adf.Triggers | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'Credential'
        {
            $r = $adf.Credentials | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'Factory'
        {
            $r = $adf.Factories | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'ManagedVirtualNetwork'
        {
            $r = $adf.ManagedVirtualNetwork | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        default
        {
            Write-Error "ADFT0014: Type [$type] is not supported."
        }
    }

    #$r = $adf.AllObjects() | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    Write-Debug ($r | Format-List | Out-String)
    Write-Debug "END: Get-AdfObjectByName()"
    return $r
}
