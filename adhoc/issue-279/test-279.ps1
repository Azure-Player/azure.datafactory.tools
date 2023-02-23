Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module 
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# & .\adhoc\~~Load-all-cmdlets-locally.ps1
. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session

# Import Helper functions
Import-Module -Name '.\test\TestHelper' -Force


$DataFactoryName = "SQLPlayerDemo"
$RootFolder = "test\adf2"
Import-AdfFromFolder -FactoryName $DataFactoryName -RootFolder $RootFolder -ErrorAction Stop

# Get-ReferencedObjects TEST
$RootFolder = ".\test\adf2"
$Name = 'pipeline\SynapseNotebook1'
$o = Get-AdfObjectFromFile -FullPath "$($RootFolder)\$Name.json"
$refs = Get-ReferencedObjects -obj $o
$refs[0]
$refs[1]

[AdfObjectName]::new($refs[0])
[AdfObjectName]::new($refs[1])

$FullName = $refs[0]


$FullName.GetType()
$FullName = $refs[1]
$FullName
$m = [regex]::matches($FullName, '([a-zA-Z]+)\.([a-zA-Z 0-9\-_]+)@?(.*)')
$m
if ($m.Success -eq $false) {
    throw "ADFT0028: Expected format of name for 'FullName' input parameter is: objectType.objectName[@folderName]"
}
[AdfObject]::AssertType($m.Groups[1].Value)


foreach ($r in $refs) {
    $oname = [AdfObjectName]::new($r)
    $o.AddDependant( $oname.Name, $oname.Type )
}

