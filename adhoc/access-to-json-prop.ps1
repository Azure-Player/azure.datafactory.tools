.\debug\~~Load-all-cmdlets-locally.ps1
$Stage = 'UAT'
$DataFactoryName = "SQLPlayerDemo-$Stage"
$RootFolder = "x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo\SQLPlayerDemo"
Test-Path -Path $RootFolder | Out-Null

Clear-Host
$adf = Import-AdfFromFolder -RootFolder "$RootFolder" -FactoryName $DataFactoryName
Write-Host ($adf | Format-List | Out-String)

$depobj = Get-AdfObjectByName -adf $adf -name "LS_AzureKeyVault" -type "LinkedService"
$depobj
$depobj = Get-AdfObjectByName -adf $adf -name "Output_Binary"

Write-Host "depobj:"
$depobj
$depobj.GetType().FullName

Clear-Host
Update-PropertiesFromCsvFile -adf $adf -stage 'uat'
Clear-Host
Update-PropertiesFromCsvFile -adf $adf -stage 'broken'


$file = "x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo\SQLPlayerDemo\pipeline\PL_CopyMovies.json"
$json = (Get-Content $file | ConvertFrom-Json)
$prop = "$($_.name).properties.$($_.path) = `"$($_.value)`""
#Invoke-Expression "`$json.properties.$($_.path) = `"$($_.value)`""

$json.properties.activities[0].outputs[0].parameters.BlobContainer
$json.properties.activities[] | select 


https://programminghistorian.org/en/lessons/json-and-jq
https://jqplay.org/

$JSONFile = ConvertFrom-Json "$(get-content ".\ConfigurationData.json")"
$ConfigurationData = @{}
$JSONFile | get-member -MemberType NoteProperty | Where-Object{ -not [string]::IsNullOrEmpty($JSONFile."$($_.name)")} | ForEach-Object {$ConfigurationData.add($_.name,$JSONFile."$($_.name)")}

$QuickJson | get-member -MemberType NoteProperty | Where-Object{ -not [string]::IsNullOrEmpty($QuickJson."$($_.name)")} | ForEach-Object {$MyHash.add($_.name, $QuickJson."$($_.name)")}

$json.properties.activities | get-member -MemberType NoteProperty
https://html.developreference.com/article/12424488/How+to+sort+an+object+by+keys+using+powershell


# Debug OFF
$DebugPreference = "SilentlyContinue"




# Reading CSV
$configFileName1 = "x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\deployment\config-uat.csv"
$configFileName2 = "x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\deployment\config-badformat.csv"
$configFileName3 = "x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\deployment\config-c002.csv"
$configFileName = $configFileName1
$configtxt = Get-Content $configFileName | Out-String
$configcsv = ConvertFrom-Csv $configtxt 
$configcsv


$configcsv.GetType().BaseType #Array
$configcsv.Count #3 rows
$row0 = $configcsv[0]
$row0


$proc_header = "type","name","path","value","empty"
$configcsvh = ConvertFrom-Csv $configtxt -Header $proc_header
$configcsvh

. ".\private\Read-CsvConfigFile.ps1"
$csv = Read-CsvConfigFile -Path $configFileName1
$csv = Read-CsvConfigFile -Path $configFileName2
$csv = Read-CsvConfigFile -Path $configFileName3
$csv



$RootFolder = "x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\"
$adf = Import-AdfFromFolder -RootFolder "$RootFolder" -FactoryName 'coscos'
Write-Host ($adf | Format-List | Out-String)

$o = Get-AdfObjectByName -adf $adf -name "PL_Wait_Dynamic" -type "pipeline"
$o
$o.Body.properties.parameters
$o.Body.properties.parameters.WaitInSec

$v1 = "{""type"": ""int32""}"
$v1
$v2 = ConvertFrom-Json $v1
$v2
$o.Body.properties.parameters.WaitInSec = $v1
$o.Body.properties.parameters.WaitInSec = $v2
$o.Body.properties.parameters.WaitInSec


$v1 = "{'type': 'int32','defaultValue': 22}"
$v2 = ConvertFrom-Json $v1
$o.Body.properties.parameters.WaitInSec = $v2
$o.Body.properties.parameters.WaitInSec

$o.Body.properties.parameters.WaitInSec.GetType()


Update-PropertiesFromCsvFile -adf $adf -stage 'X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\deployment\config-c002a.csv'
Update-PropertiesFromCsvFile -adf $adf -stage 'X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\deployment\config-c002b.csv'
Update-PropertiesFromCsvFile -adf $adf -stage 'X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\deployment\config-c002.csv'
Update-PropertiesFromCsvFile -adf $adf -stage 'X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test\BigFactorySample2\deployment\config-commented.csv'


# Environment variables 
Get-Item -Path Env:* | Sort-Object Name
$env:COMPUTERNAME

$value = 'Some text $env:COMPUTERNAME123'
Write-Host "$value"
$expval = $ExecutionContext.InvokeCommand.ExpandString($value);
Write-Host "$expval"


$value = 'Some text $($env:COMPUTERNAME)123'
Write-Host "$value"
$expval = $ExecutionContext.InvokeCommand.ExpandString($value);
Write-Host "$expval"

# https://nerdymishka.com/articles/expand-string-in-powershell/

$version = "1.2.3"
$value = 'Some text $version'
Write-Host "$value"
$expval = $ExecutionContext.InvokeCommand.ExpandString($value);
Write-Host "$expval"

Get-Variable 
Get-Variable -s 0

$Env:MappedSecret = 'SecretPa$$w0rd'
$Env:COMPUTERNAME = 'abc'

$local:PSHOME
$local:ExecutionContext.InvokeCommand
$global:ShellId

$env
