class AdfDeploymentState {
    [datetime] $LastUpdate 
    [hashtable] $Deployed = @{}
    [string] $adftoolsVer = ''
    [string] $Algorithm = 'MD5'

    AdfDeploymentState ([string] $ver)
    {
        $this.adftoolsVer = $ver
    }

    [int] SetStateFromAdf ([Adf] $adf)
    {
        $cnt = 0
        $adf.AllObjects() | ForEach-Object {
            $hash = $_.GetHash()
            $name = $_.FullName()
            if ($name -notlike 'factory*' -and $_.Deployed) {
                if ($this.Deployed.ContainsKey($name))
                {
                    $this.Deployed[$name] = $hash
                    Write-Verbose "[UPDATED] hash for $name = $hash"
                    $cnt++
                } else {
                    $this.Deployed.Add($name, $hash)
                    Write-Verbose "  [ADDED] hash for $name = $hash"
                    $cnt++
                }
            }
        }
        # Remove deleted objects from Deployment State
        $adf.DeletedObjectNames | ForEach-Object {
            $this.Deployed = Remove-ItemFromCollection -col $this.Deployed -item $_
            Write-Verbose "[DELETED] hash for $_"
        }
        $this.LastUpdate = [System.DateTime]::UtcNow
        return $cnt;
    }


}

function Get-StateFromService {
    [CmdletBinding()]
    param ($targetAdf)

        $res = Get-GlobalParam -ResourceGroupName $targetAdf.ResourceGroupName -DataFactoryName $targetAdf.DataFactoryName
        $d = @{}

        try {
            $InputObject = $res.properties.adftools_deployment_state.value.Deployed
            $d = Convert-PSObjectToHashtable $InputObject
        }
        catch {
            Write-Verbose $_.Exception
        }

        return $d
}



class AdfGlobalParam {
    $type = "Object"
    $value = $null

    AdfGlobalParam ($value) 
    {
        $this.value = $value
    }

}
