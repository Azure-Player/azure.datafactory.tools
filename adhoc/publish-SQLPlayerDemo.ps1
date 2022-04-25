$DebugPreference = 'Continue'
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'

$SubscriptionName = 'MVP'
$ResourceGroupName = 'rg-blog-uat'
$DataFactoryName = 'adf-blog-uat'
$Location = "NorthEurope"
$RootFolder = "x:\!WORK\GitAz\sqlplayer\Blog\blog-demo\adf-blog\"

Clear-Host
Import-Module .\azure.datafactory.tools.psd1 -Force
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Stage "UAT"
#Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"

Get-Help azure.datafactory.tools



#############################################################
###### ADF: SQLPlayerDemo -> SQLPlayerDemo-UAT
#############################################################
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'
Get-Module -Name "Az.DataFactory"
#Import-Module ".\azure.datafactory.tools.psd1" -Force
Remove-Module azure.datafactory.tools
Import-Module azure.datafactory.tools
Get-Module azure.datafactory.tools

$SubscriptionName = 'MVP'
Set-AzContext -Subscription $SubscriptionName

$Env:StorageAccountKey = 'pQ7y2+E8dQ3mhSKN********bUbu9iWabCQm5Kw=='

$ResourceGroupName = 'rg-devops-factory'
$Stage = 'UAT'
$DataFactoryName = "SQLPlayerDemo-$Stage"
$Location = "NorthEurope"
$RootFolder = "x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo\SQLPlayerDemo"
$StageFile = 'x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo\SQLPlayerDemo\deployment\config-uat.csv'


#Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"   `
#    -Stage "UAT" -Location $Location
$o = New-AdfPublishOption 
$o.DeleteNotInSource = $true
$o.Excludes.Add('integrationruntime.*','')
$o.Excludes.Add('LinkedService.LS_SQLDev19_WWI','')
$o.Includes.Add('*.*@Stack*', '')
$o.Includes.Add('*.LS_BlobSqlPlayer', '')
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"   `
    -Stage "$StageFile" -Location $Location -Method "AzResource" -Option $o


# Publish only one file:
$Env:StorageAccountKey = 'abc=='
$opt = New-AdfPublishOption 
$opt.Includes.Add("pipeline.PL_CopyMovies", "")
$opt.DeleteNotInSource = $false
$opt.StopStartTriggers = $false
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"   `
    -Stage "UAT" -Location $Location -Option $opt


# Publish AzureIR with VNET only (20/04/2021)
$opt = New-AdfPublishOption 
$opt.Includes.Add("*.AzureIR-VNET2", "")
$opt.DeleteNotInSource = $false
$opt.StopStartTriggers = $false
# Error
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"   `
    -Location $Location -Option $opt 
# Works but deploys only standard AzureIR
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"   `
    -Location $Location -Option $opt -Method 'AzDataFactory'


# Publish Array Global Param only (20/04/2021)
Import-Module .\azure.datafactory.tools.psd1 -Force
$opt = New-AdfPublishOption 
$opt.Includes.Add("factory.*", "")
$opt.DeleteNotInSource = $false
$opt.StopStartTriggers = $false
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"   `
    -Location $Location -Option $opt -Method 'AzDataFactory'


$adf = Import-AdfFromFolder -RootFolder 'X:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo\SQLPlayerDemo\' -FactoryName 'SQLPlayerDemo'
$adf.GlobalFactory.body = (Get-Content -Path $adf.Factories[0].FileName -Encoding "UTF8" | Out-String)

$globalFactoryObject = [Newtonsoft.Json.Linq.JObject]::Parse($adf.GlobalFactory.body)
#$globalParametersObject = [Newtonsoft.Json.Linq.JObject]::Parse($globalParametersJson)
$globalParametersObject = $globalFactoryObject.properties.globalParameters

$newGlobalParameters = New-Object 'system.collections.generic.dictionary[string,Microsoft.Azure.Management.DataFactory.Models.GlobalParameterSpecification]'
foreach ($gp in $globalParametersObject.GetEnumerator()) {
    Write-Host "Adding global parameter:" $gp.Key
    $globalParameterValue = $gp.Value.ToObject([Microsoft.Azure.Management.DataFactory.Models.GlobalParameterSpecification])
    $globalParameterValue
    $newGlobalParameters.Add($gp.Key, $globalParameterValue)
}



Import-Module .\azure.datafactory.tools.psd1 -Force

$opt = New-AdfPublishOption 
#$opt.Includes.Add("*.CopyTableStorage", "")
# $opt.Includes.Add("*.PL_Wait", "")
# $opt.Includes.Add("*.AW2016_Product_blob", "")
# $opt.Includes.Add("*.LS_BlobSqlPlayer", "")
$opt.DeleteNotInSource = $false
$opt.StopStartTriggers = $false
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"   `
    -Stage "UAT" -Location $Location -Method "ARM"  -Option $opt

$adf.Arm


$opt
$a = Get-Member -InputObject $opt -name "DeleteNotInSource" -Membertype "Properties"
$a -eq $null


function Invoke-ArmEncoding222 ( $o, $prefix ) {
    foreach ($info in $o.PSObject.Properties) {
        if ($info.Value.GetType().Name -eq "ArrayList" )
        {
            Invoke-ArmEncoding $info.Value $info.Name
        }
        else 
        {
            Write-Host "$prefix/$($info.Name)[$($info.Value.GetType().Name)]: $($info.Value)"
        }
    }
}

function Invoke-ArmEncoding {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    process {
        if ($null -eq $InputObject) {
            return $null
        }
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    Invoke-ArmEncoding -InputObject $object
                }
            )
            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = Invoke-ArmEncoding -InputObject $property.Value
                $property.Name
                $hash[$property.Name]
            }
            #$hash
        } else {
            $InputObject.PSObject.Properties.Name + '.'
        }
    }
}

Invoke-ArmEncoding $adf.Arm



$adf.Arm.PSObject.Properties.Name

$adf.Arm['contentVersion']
$adf.Arm.resources


function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
 
    process {
        ## Return null if the input is null. This can happen when calling the function
        ## recursively and a property is null
        if ($null -eq $InputObject) {
            return $null
        }
 
        ## Check if the input is an array or collection. If so, we also need to convert
        ## those types into hash tables as well. This function will convert all child
        ## objects into hash tables (if applicable)
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )
 
            ## Return the array but don't enumerate it because the object may be pretty complex
            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
            ## Convert it to its own hash table and return it
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hash
        } else {
            ## If the object isn't an array, collection, or other object, it's already a hash table
            ## So just return it.
            $InputObject
        }
    }
}


# We can then call this function via pipeline:
$json | ConvertFrom-Json | ConvertTo-HashTable

$a = $adf.Arm | ConvertTo-Json | ConvertFrom-Json | ConvertTo-HashTable
$a.resources







$f = "X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\arm-deployment3.json" 
New-AzResourceGroupDeployment -ResourceGroupName "$ResourceGroupName" -TemplateFile $f






$arm = New-Object -TypeName ArmTemplate
$arm.resources = [System.Collections.ArrayList]::new()

$r = New-Object -TypeName ArmResource
$r.name = "rihfure565g"
$r.type = "rehfirheighireg"
$arm.resources.Add($r)
$arm

ConvertTo-Json $arm |  Set-Content -Path "arm-deployment.json" 





$DebugPreference = 'SilentlyContinue'

$adfInstance = Get-AdfFromService -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
$adfInstance.DataFlows[0].GetType()
$adfInstance.Pipelines[0].GetType()
$adfInstance.LinkedServices[0].GetType()
$adfInstance.IntegrationRuntimes[0].GetType()
$adfInstance.Triggers[0].GetType()


