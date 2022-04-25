Import-Module ".\azure.datafactory.tools.psd1" -Force
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'

$RootFolder = "C:\Users\kamil\AppData\Local\Temp\ADFTools-jycwcfzq.2xc\BigFactorySample2"
$ResourceGroupName = 'rg-devops-factory'
$guid = '5889b15h'
$DataFactoryOrigName = 'BigFactorySample2'
$DataFactoryName = $script:DataFactoryOrigName + "-$guid"

$opt = New-AdfPublishOption 
$opt.StopStartTriggers = $false
$opt.DeleteNotInSource = $true

Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" -Option $opt




# Can I read dependencies from service-objects?
$s = Get-AdfFromService -ResourceGroupName "$ResourceGroupName" -FactoryName "$DataFactoryName"
$adf = Import-AdfFromFolder -FactoryName "$DataFactoryName" -RootFolder $RootFolder
$s
$s.AllObjects()
$s.Triggers.Properties
$s.Pipelines[0]

# --------------------------------------
# Delete by Az.Resource

$ResourceGroupName = 'rg-datafactory'
$DataFactoryName = 'BigFactorySample2'



Get-AzResource -ResourceGroupName $ResourceGroupName | ft
$adf = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $DataFactoryName
$adf.ResourceId


Get-AzResource -ResourceType Microsoft.DataFactory/factories | ft

Get-AzResource -ResourceType "Microsoft.DataFactory/factories/$DataFactoryName/pipelines" | ft
Get-AzResource -ResourceType "Microsoft.DataFactory/factories/pipelines" | ft

Get-AzResource -ResourceId $adf.ResourceId
Get-AzResource -ResourceId "$($adf.ResourceId)/pipelines/*"  #badrequest
Get-AzResource -ResourceId "$($adf.ResourceId)/pipelines" |ft
Get-AzResource -ResourceId "$($adf.ResourceId)/triggers" |ft
Get-AzResource -ResourceId "$($adf.ResourceId)/datasets" |ft

$o = Get-AzResource -ResourceId "$($adf.ResourceId)/datasets/CADOutput1"
$o | Get-Member
$o.properties




$ResourceGroupName = 'kamilnow-rg1'
$DataFactoryName = 'adf-simpledeployment'

$adf = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $DataFactoryName
Get-AzResource -ResourceId "$($adf.ResourceId)/linkedServices" | ft
$o = Get-AzResource -ResourceId "$($adf.ResourceId)/linkedServices/LS_ADLS"
ConvertTo-Json $o -Depth 100

$o = Get-AzDataFactoryV2linkedService -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Name 'LS_ADLS'
ConvertTo-Json $o -Depth 100

Get-AzResource -ResourceId "$($adf.ResourceId)/linkedServices/LS_AzureKeyVault"
Remove-AzResource -ResourceId "$($adf.ResourceId)/linkedServices/LS_AzureKeyVault"

















Get-AzResource -ResourceGroupName 'rg-blobstorage' | ft
Get-AzStorageAccount -ResourceGroupName 'rg-blobstorage'
Get-AzStorageAccount -ResourceGroupName 'rg-pademo'

