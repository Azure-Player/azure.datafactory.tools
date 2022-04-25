$RootFolder = "x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo\BigFactoryTestWrongRef\"

Clear-Host
Import-Module .\azure.datafactory.tools.psd1 -Force

$r = Test-AdfCode -RootFolder $RootFolder -ErrorAction Continue
$r
$ErrorActionPreference = Continue
