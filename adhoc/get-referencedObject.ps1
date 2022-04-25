# Get
$a = Get-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName"
$a
$a.Identity
$ds = Get-AzDataFactoryV2Dataset -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"
$ds[0].Properties
$ds[0].GetType()
Az.DataFactory.PSDataSet $ds0 = $ds[0]
$ds.GetType()
$a.GetType()

Get-AzDataFactoryV2IntegrationRuntime -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"
Get-AzDataFactoryV2LinkedService -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"
Get-AzDataFactoryV2Pipeline -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"
Get-AzDataFactoryV2DataFlow -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"
Get-AzDataFactoryV2Trigger -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"


Get-AzDataFactoryV2DataFlow -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Name "DF_DataRelay"



Import-AdfObjects -Adf $adf -All $adf.DataFlows -RootFolder $RootFolder -SubFolder "dataflow" | Out-Null
Import-AdfObjects -Adf $adf -All $adf.Triggers -RootFolder $RootFolder -SubFolder "trigger" | Out-Null

$RootFolder = "x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo\SQLPlayerDemo\"

$adfSource = Import-AdfFromFolder -FactoryName $DataFactoryName -RootFolder "$RootFolder"
$adfIns = Get-AdfFromService -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
$adfTargetObj = $adfInstance.DataFlows[0]
$adfTargetObj.DataFlowName

$adfInstance.DataFlows[1].Name
$adfInstance.Pipelines[0].Name

$b = new-object Microsoft.Azure.Commands.DataFactoryV2.Models.AdfSubResource
$o = new-object Microsoft.Azure.Commands.DataFactoryV2.Models.PSTrigger

$typeNameDic = @{ 
    "PSDataFlow" = "DataFlowName"
    "PSPipeline" = "PipelineName"
    "PSLinkedService" = "LinkedServiceName"
    "PSSelfHostedIntegrationRuntime" = "Name"
    "PSIntegrationRuntime" = "Name"
    "PSTrigger" = "TriggerName"
}

Remove-AdfObjectIfNotInSource -adfSource $adfSource -adfTargetObj 

$adfTargetObj = $adfIns.DataSets[23]

$adfIns.Triggers[1].Properties.DependsOn

[Microsoft.Azure.Commands.DataFactoryV2.Models.PSTrigger]$trigger = $adfIns.Triggers[1]

$trigger.Properties


#todo: provide function to delete listed objects



$type = 'PSIntegrationRuntime'
if ($type -like 'PS*') { $type = $type.Substring(2) }
$type

# regex
$txt = '			{
    "pipelineReference": {
        "referenceName": "PL_Wait",
        "type": "PipelineReference"
    }
},
{
    "pipelineReference": {
        "referenceName": "PL_Something",
        "type": "ojojojoj"
    }
}
'
$o = New-Object -TypeName AdfObject 
$m = [regex]::matches($txt,'"referenceName": ?"(?<r>.+?)",[\n\r\s]+"type": ?"(?<t>.+?)"')
$m | ForEach-Object {
    $_.Groups['r'].Value
    $_.Groups['t'].Value
    #$o.DependsOn.Add(  @{ $_.Groups['r'].Value = $_.Groups['t'].Value } ) | Out-Null
    $o.AddDependant( $_.Groups['r'].Value, $_.Groups['t'].Value ) | Out-Null
}

$o.DependsOn.getEnumerator() | ForEach-Object {
    Write-Host ("Key = " + $_.key + " and Value = " + $_.value);
}

$o.DependsOn | ForEach-Object {
    $_
    $name = $_.Name
    $type = $_.Value
    Write-Verbose ("Depends on: [$type].[$name]")
}




$hash = @{
    a = 1
    b = 2
    c = 3
}
$hash.Add('rfrf','referf')



$ResourceGroupName = 'rg-devops-factory'
$Stage = 'UAT'
$DataFactoryName = "SQLPlayerDemo-$Stage"

$t = Get-AzDataFactoryV2Trigger -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"
$t

Write-Output $t[1]
Write-Output $t[1].Properties

Write-Output $t[0]
Write-Output $t[0].Properties



$url = "https://*****.westeurope.logic.azure.com:443/workflows/***/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=***"
$body = "test body"
$postParams = @{username='me';moredata='qwerty'}
Invoke-WebRequest -Uri $url -Method POST -Body $postParams

    

