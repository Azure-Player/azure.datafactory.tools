# .\debug\~~Load-all-cmdlets-locally.ps1
$ResourceGroupName = 'rg-devops-factory'
$Stage = 'UAT'
$DataFactoryName = "SQLPlayerDemo-$Stage"
$RootFolder = "x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo\SQLPlayerDemo\"
$Location = "NorthEurope"
Test-Path -Path $RootFolder | Out-Null

Clear-Host
$adf = Import-AdfFromFolder -RootFolder "$RootFolder" -FactoryName $DataFactoryName
Write-Host ($adf | Format-List | Out-String)

$adf.Pipelines[0]
$r = $adf.GetObjectsByFullName('*.copy*')
$r

$r = $adf.GetObjectsByFolderName('JSON')
$r
$r.GetType()

@(0,2,10).ForEach({ 
    $o = $adf.Pipelines[$_].Body.properties
    $o.PSobject.Properties.Name -contains "folder"
    $f = $adf.Pipelines[$_].Body.properties.folder.name
    Write-Host ("$f is null  ->  $($null -eq $f)")
})

$adf.GetObjectsByFolderName("$null")
$adf.GetObjectsByFolderName('JSON')


#
# FINAL TESTS: Apply to Options
#

Import-Module ".\azure.datafactory.tools.psd1" -Force
Get-Module azure.datafactory.tools

$VerbosePreference = 'SilentlyContinue'
$adf = Import-AdfFromFolder -RootFolder "$RootFolder" -FactoryName $DataFactoryName

$opt = New-AdfPublishOption
$opt.StopStartTriggers = $false
$list = $adf.GetObjectsByFolderName('JSON')
$opt.Includes += $list

$list2 = $adf.GetObjectsByFolderName('Copy')
$opt.Includes += $list2
$opt.Includes

Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" `
    -Stage "UAT" `
    -Location "$Location" `
    -Option $opt




