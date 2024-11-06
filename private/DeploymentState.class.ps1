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

function Get-StateFromStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] $DataFactoryName, 
        [Parameter(Mandatory)] $LocationUri
        )

    $moduleName = $MyInvocation.MyCommand.Module.Name
    $moduleVersion = (Get-Module -Name $moduleName).Version.ToString()
    $Suffix = "adftools_deployment_state.json"
    $ds = [AdfDeploymentState]::new($moduleVersion)
    $storageAccountName = Get-StorageAccountNameFromUri $LocationUri
    $storageContext = New-AzStorageContext -UseConnectedAccount -StorageAccountName $storageAccountName
    $blob = [Microsoft.Azure.Storage.Blob.CloudBlockBlob]::new("$LocationUri/$DataFactoryName.$Suffix")
    Write-Host "Ready to read file from storage: $($blob.Uri.AbsoluteUri)"

    $storageContainer = Get-AzStorageContainer -Name $blob.Container.Name -Context $storageContext
    $folder = $blob.Parent.Prefix
    $FileRef = $storageContainer.CloudBlobContainer.GetBlockBlobReference("$folder$DataFactoryName.$Suffix")
    if ($FileRef.Exists()) {
        $FileContent = $FileRef.DownloadText()
        # $FileRef.DownloadText() | Set-Content $Suffix
        # $FileContent = Get-Content $Suffix -Encoding 'UTF8'
        # foreach ($line in $FileContent) {
        #     Write-Debug $line
        # }
        $json = $FileContent | ConvertFrom-Json
        $ds.Deployed = Convert-PSObjectToHashtable $json.Deployed
        $ds.adftoolsVer = $json.adftoolsVer
        $ds.Algorithm = $json.Algorithm
        $ds.LastUpdate = $json.LastUpdate
        Write-Host "Deployment State loaded from storage."
        return $ds
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

    $localFile = "adftools_deployment_state.json"
    $dsjson = ConvertTo-Json $ds -Depth 5
    Write-Verbose "--- Deployment State: ---`r`n $dsjson"

    $fullFilePath = Save-ContentUTF8 -Path $localFile -Value $dsjson
    $isExist = Test-Path $fullFilePath
    Write-Host "Tested file location: $fullFilePath  (result: $isExist)"
    Write-Host "Current location: $(Get-Location)"
    $storageAccountName = Get-StorageAccountNameFromUri $LocationUri
    $storageContext = New-AzStorageContext -UseConnectedAccount -StorageAccountName $storageAccountName
    $blob = [Microsoft.Azure.Storage.Blob.CloudBlob]::new("$LocationUri/$DataFactoryName.$localFile")
    $r = Set-AzStorageBlobContent -ClientTimeoutPerRequest 5 -ServerTimeoutPerRequest 5 -CloudBlob $blob -File $fullFilePath -Context $storageContext -Force

    Write-Host "Deployment State saved to storage: $($r.BlobClient.Uri)"
}

# Function to get Storage Account name from URI
function Get-StorageAccountNameFromUri($uri) {
    $accountName = ($uri -split '\.')[0].Substring(8)  # Assumes URI starts with "https://"
    return $accountName
}

function Save-ContentUTF8($Path, $Value) {
    Write-Debug "Save-ContentUTF8::Begin: $Path $Value"
    $fullPath = Resolve-NonExistPath -Path $Path    #.NET function (WriteAllLines) requires full path, otherwise "default" location != PS default location
    Write-Debug "Save-ContentUTF8::fullPath: $fullPath"
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False  # with BOM-less
    [System.IO.File]::WriteAllLines($fullPath, $Value, $Utf8NoBomEncoding)
    Write-Debug "Save-ContentUTF8::End: Saved UTF8 file to location: $Path"
    return $fullPath
}

function Resolve-NonExistPath($Path) {
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}