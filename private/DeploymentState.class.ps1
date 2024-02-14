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


    [Boolean] IsTriggerDisabled([string] $ObjectName)
    {
        return $this.DisabledTriggerNames -contains $ObjectName
    }

}

# function Get-StateFromService {
#     [CmdletBinding()]
#     param ($targetAdf)

#         $res = Get-GlobalParam -ResourceGroupName $targetAdf.ResourceGroupName -DataFactoryName $targetAdf.DataFactoryName
#         $d = @{}

#         try {
#             $InputObject = $res.properties.adftools_deployment_state.value.Deployed
#             $d = Convert-PSObjectToHashtable $InputObject
#         }
#         catch {
#             Write-Verbose $_.Exception
#         }

#         return $d
# }

function Get-StateFromStorage {
    [CmdletBinding()]
    param ($DataFactoryName)

    $ds = [AdfDeploymentState]::new($verStr)
    $ctx = New-AzStorageContext -UseConnectedAccount -StorageAccountName "sqlplayer2020"
    $blob = Get-AzStorageBlobContent -Container "adftools" -Blob "$DataFactoryName.adfdeploymentstate.json" -Destination "adfdeploymentstate.json" -Force -Context $ctx
    if ($blob) {
        $txt = Get-Content -Path "adfdeploymentstate.json" -Raw -Encoding UTF8
        Write-Host $txt
        [AdfDeploymentState] $ds = $txt
    }
    return $ds
}

function Set-StateToStorage {
    [CmdletBinding()]
    param ($ds, $DataFactoryName)

    $dsjson = ConvertTo-Json $ds -Depth 5
    Write-Verbose "--- Deployment State: ---`r`n $dsjson"

    Set-Content -Path "adfdeploymentstate.json" -Value $dsjson -Encoding UTF8
    $ctx = New-AzStorageContext -UseConnectedAccount -StorageAccountName "sqlplayer2020"
    Set-AzStorageBlobContent -Container "adftools" -File "adfdeploymentstate.json" -Context $ctx -Blob "$DataFactoryName.adfdeploymentstate.json" -Force

}



# class AdfGlobalParam {
#     $type = "Object"
#     $value = $null

#     AdfGlobalParam ($value) 
#     {
#         $this.value = $value
#     }

# }
