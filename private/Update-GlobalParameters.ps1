function Update-GlobalParameters {
    [CmdletBinding()]
param
(
    [Parameter(Mandatory)] [Adf] $adf
)

    Write-Debug "BEGIN: Update-GlobalParameters"

    if ($adf.GlobalFactory.body.Length -gt 0)
    {
        $newGlobalParameters = New-Object 'system.collections.generic.dictionary[string,Microsoft.Azure.Management.DataFactory.Models.GlobalParameterSpecification]'
        Write-Verbose "Parsing JSON..."
        $globalFactoryObject = [Newtonsoft.Json.Linq.JObject]::Parse($adf.GlobalFactory.body)

        $gpExist = $null
        $propertiesExist = Get-Member -InputObject $adf.GlobalFactory.GlobalParameters -name "properties" -Membertype "Properties"
        if ($null -ne $propertiesExist) {
            $gpExist = Get-Member -InputObject $adf.GlobalFactory.GlobalParameters.properties -name "globalParameters" -Membertype "Properties"
        }
        if ($null -ne $gpExist)
        {
            $globalParametersObject = $globalFactoryObject.properties.globalParameters

            Write-Host "Adding global parameter..."
            foreach ($gp in $globalParametersObject.GetEnumerator()) {
                Write-Host "- " $gp.Key
                $globalParameterValue = $gp.Value.ToObject([Microsoft.Azure.Management.DataFactory.Models.GlobalParameterSpecification])
                $newGlobalParameters.Add($gp.Key, $globalParameterValue)
            }

            if ($newGlobalParameters.Count -gt 0) {
                Write-Verbose "Updating $($newGlobalParameters.Count) global parameters..."
                Set-GlobalParam($adf)
                Write-Host "Update of $($newGlobalParameters.Count) global parameters complete."
            }
        }
    }
    
    Write-Debug "END: Update-GlobalParameters"

}
