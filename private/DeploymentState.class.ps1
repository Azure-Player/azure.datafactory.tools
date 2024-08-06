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
    param (
        [Parameter(Mandatory)] $DataFactoryName, 
        [Parameter(Mandatory)] $LocationUri
        )

    $Suffix = "adfdeploymentstate.json"
    $ds = [AdfDeploymentState]::new("1.0.0")
    $storageAccountName = Get-StorageAccountNameFromUri $LocationUri
    $ctx = New-AzStorageContext -UseConnectedAccount -StorageAccountName $storageAccountName
    $blob = [Microsoft.Azure.Storage.Blob.CloudBlockBlob]::new("$LocationUri/$DataFactoryName.$Suffix")
    Write-Host " Ready to read file from storage - Uri: $($blob.Uri.AbsoluteUri)"
    #$file = Get-AzStorageBlobContent -CloudBlob $blob -Destination $Suffix -Context $ctx            #-ErrorAction SilentlyContinue
    #$blob = Get-AzStorageBlobContent -Container "adftools" -Blob "$DataFactoryName.$Suffix" -Destination $Suffix -Force -Context $ctx -ErrorAction SilentlyContinue
    $file = Get-AzStorageBlobContent -Container $blob.Container.Name -Blob $blob.Name -Destination $Suffix -Context $ctx -Force           #-ErrorAction SilentlyContinue
    if ($file) {
        $txt = Get-Content -Path $Suffix -Raw -Encoding UTF8
        Write-Host $txt -BackgroundColor Blue
        [AdfDeploymentState] $ds = $txt
        Write-Host "Deployment State loaded from storage."
    }
    else {
        Write-Host "No Deployment State found."
    }
    return $ds
}

function Set-StateToStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] $ds, 
        [Parameter(Mandatory)] $DataFactoryName, 
        [Parameter(Mandatory)] $LocationUri
        )

    $Suffix = "adfdeploymentstate.json"
    $dsjson = ConvertTo-Json $ds -Depth 5
    Write-Verbose "--- Deployment State: ---`r`n $dsjson"

    Set-Content -Path $Suffix -Value $dsjson -Encoding UTF8
    $storageAccountName = Get-StorageAccountNameFromUri $LocationUri
    $ctx = New-AzStorageContext -UseConnectedAccount -StorageAccountName $storageAccountName
    $blob = [Microsoft.Azure.Storage.Blob.CloudBlob]::new("$LocationUri/$DataFactoryName.$Suffix")
    $r = Set-AzStorageBlobContent -CloudBlob $blob -File $Suffix -Context $ctx -Force 

    Write-Host "Deployment State saved to storage. Uri: $($r.BlobClient.Uri)"
}

# Function to get Storage Account name from URI
function Get-StorageAccountNameFromUri($uri) {
    $accountName = ($uri -split '\.')[0].Substring(8)  # Assumes URI starts with "https://"
    return $accountName
}




# class AdfGlobalParam {
#     $type = "Object"
#     $value = $null

#     AdfGlobalParam ($value) 
#     {
#         $this.value = $value
#     }

# }
