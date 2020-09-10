function Update-GlobalParameters {
    [CmdletBinding()]
param
(
    [Parameter(Mandatory)] [Adf] $adf,
    [Parameter(Mandatory)] $targetAdf
)

    Write-Debug "BEGIN: Update-GlobalParameters"

    if ($adf.GlobalFactory.body.Length -gt 0)
    {
        $newGlobalParameters = New-Object 'system.collections.generic.dictionary[string,Microsoft.Azure.Management.DataFactory.Models.GlobalParameterSpecification]'
        Write-Verbose "Parsing JSON..."
        $globalFactoryObject = [Newtonsoft.Json.Linq.JObject]::Parse($adf.GlobalFactory.body)
        #$globalParametersObject = $globalFactoryObject.properties.globalParameters

        $gpExist = Get-Member -InputObject $adf.GlobalFactory.GlobalParameters -name "properties" -Membertype "Properties"
        if ($null -ne $gpExist)
        {

            Write-Host "Adding global parameter..."
            foreach ($p in $adf.GlobalFactory.GlobalParameters.properties.globalParameters.PSObject.Properties)
            {
                # $p.Name
                # $p.Value.type
                # $p.Value.value
                $gpspec = New-Object 'Microsoft.Azure.Management.DataFactory.Models.GlobalParameterSpecification'
                $gpspec.Type = $p.Value.type
                $gpspec.Value = $p.Value.value
                $globalParameterValue = $gpspec
                $newGlobalParameters.Add($p.Name, $globalParameterValue)
            }
            $targetAdf.GlobalParameters = $newGlobalParameters

            # Write-Host "--- newGlobalParameters ---"
            #$newGlobalParameters.Values | Out-Host

            Write-Verbose "Updating $($newGlobalParameters.Count) global parameters..."
            Set-AzDataFactoryV2 -InputObject $targetAdf -Force | Out-Null
            Write-Host "Update of $($newGlobalParameters.Count) global parameters complete."
        }
    }
    
    Write-Debug "END: Update-GlobalParameters"

}
