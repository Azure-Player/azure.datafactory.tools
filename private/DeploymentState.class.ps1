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
        $this.LastUpdate = [System.DateTime]::UtcNow
        return $cnt;
    }


    [hashtable] GetStateFromService ($targetAdf)
    {
        $res = Get-GlobalParam -ResourceGroupName $targetAdf.ResourceGroupName -DataFactoryName $targetAdf.DataFactoryName
        
        try {
            $InputObject = $res.properties.adftools_deployment_state.value.Deployed
            $this.Deployed = Convert-PSObjectToHashtable $InputObject
        }
        catch {
            Write-Verbose $_.Exception
        }

        return $this.Deployed
    }

}

class AdfGlobalParam {
    $type = "Object"
    $value = $null

    AdfGlobalParam ($value) 
    {
        $this.value = $value
    }

}
