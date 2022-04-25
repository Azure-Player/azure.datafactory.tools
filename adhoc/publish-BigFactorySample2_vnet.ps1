#############################################################
###### ADF: BigFactorySample2_vnet
#############################################################
Get-Module -Name "Az.DataFactory"
Remove-Module azure.datafactory.tools -ErrorAction:Ignore
Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module azure.datafactory.tools
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

Connect-AzAccount
$SubscriptionName = 'MVP'
Set-AzContext -Subscription $SubscriptionName
Get-AzContext

$ResourceGroupName = 'rg-datafactory'
$Location = "NorthEurope"
$RootFolder = ".\test\BigFactorySample2_vnet"
$DataFactoryName = 'BigFactorySample2-test'

# Deploy ADF without one LS:
$o = New-AdfPublishOption 
$o.Excludes.Add('*.LS_SqlServer_DEV19_AW2017', '')
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" `
      -Location "$Location" -Option $o

# Deploy only ManagedVirtualNetwork
Import-Module ".\azure.datafactory.tools.psd1" -Force

$DataFactoryName = 'BigFactorySample3'
$RootFolder = 'x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo\BigFactorySample2'

$o = New-AdfPublishOption 
$o.StopStartTriggers = $false
$o.Includes.Add('manag*.*', '')
$o.Includes.Add('*.AutoRes*', '')
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" `
      -Location "$Location" -Option $o

$DataFactoryName = 'BigFactorySample3'
$RootFolder = 'x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\~InternalFiles\issue#149\ADF'
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" 

$ErrorActionPreference = 'Continue'
$VerbosePreference = 'Continue'
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Stage 'workaround'

$adf = Import-AdfFromFolder -FactoryName 'asa' -RootFolder "x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2_vnet"
$adf = Import-AdfFromFolder -FactoryName 'asa' -RootFolder "$RootFolder"
$o = $adf.ManagedVirtualNetwork[0]


# Above Failed
# API: 2018-07-01-preview DID NOT HELP

# Publishing the same via ARM Template...
$t=(Get-Date).TOString('MMdd-HHmm')
$file = 'x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\~InternalFiles\issue#149\arm\arm_template.json'
$param_file = 'x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\~InternalFiles\issue#149\arm\arm_template_parameters.json'
New-AzResourceGroupDeployment -Name "DeployADF-$t" -ResourceGroupName $ResourceGroupName -TemplateFile $file `
    -TemplateParameterFile $param_file -Mode 'Incremental'
#ARM works!


$resType = Get-AzureResourceType $obj.Type
$resName = $obj.AzureResourceName()

# correct file (contains 'properties' node)
$file = 'X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2_vnet\managedVirtualNetwork\default.json'   
# wrong file (since GA)
$file = 'X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\~InternalFiles\issue#149\ADF\managedVirtualNetwork\default.json'  

$body = (Get-Content -Path $file -Encoding "UTF8" -Raw | Out-String)
$json = $body | ConvertFrom-Json

$ResourceGroupName = 'rg-datafactory'
$DataFactoryName = 'BigFactorySample3'

New-AzResource `
-ResourceType 'Microsoft.DataFactory/factories/managedVirtualNetworks' `
-ResourceGroupName $resourceGroupName `
-Name "$DataFactoryName/default" `
-ApiVersion "2018-07-01-preview" `
-Properties $json `
-IsFullObject -Force 

$f = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName
$f
$f.Identity
$f.GlobalParameters


# 1. Deploy ADF - infra only
$ResourceGroupName = 'rg-datafactory'
$DataFactoryName = 'BigFactorySample3'



# 2. Deploy ADF - app only (without infra)

$ResourceGroupName = 'rg-datafactory'
$Location = "NorthEurope"
$RootFolder = ".\test\BigFactorySample2_vnet"
$DataFactoryName = 'BigFactorySample2-test'

# Deploy ADF without one LS:
$o = New-AdfPublishOption 
$o.Excludes.Add('*.LS_SqlServer_DEV19_AW2017', '')
##$o.Excludes.Add('managedVirtualNetwork*.*', '')    # OR
$o.Excludes.Add('*managedPrivateEndpoint.*', '')
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" `
      -Location "$Location" -Option $o

# issue 07/12/2021
$ResourceGroupName = 'rg-datafactory'
$Location = "NorthEurope"
$RootFolder = ".\test\BigFactorySample2_vnet"
$DataFactoryName = 'BigFactorySample2-test'

# Deploy ADF without managedVirtualNetwork
$o = New-AdfPublishOption 
$o.Excludes.Add('managedVirtualNetwork*.*', '')
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" `
      -Location "$Location" -Option $o -DryRun:$true


