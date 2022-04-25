
# Debug OFF
$DebugPreference = "SilentlyContinue"
Get-Module -Name "Az*"

$SubscriptionName = 'MVP'
Set-AzContext -Subscription $SubscriptionName

$ResourceGroupName = 'rg-devops-factory'
$Stage = 'UAT'
$DataFactoryName = "SQLPlayerDemo-$Stage"
$RootFolder = "x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo\SQLPlayerDemo\"
$RootFolder = $env:ADF_ExampleCode
$RootFolder

$guid = '5889b15h'
$DataFactoryName = (Split-Path -Path $env:ADF_ExampleCode -Leaf) + "-$guid"
$DataFactoryName

Clear-Host
$opt = New-AdfPublishOption
$opt.Includes.Add("trigger.*", "")
$opt.DeleteNotInSource = $true
Publish-AdfV2FromJson -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -Location 'NorthEurope' `
    -Option $opt -RootFolder $RootFolder
Get-AzDataFactoryV2Trigger -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName | ft


. "debug\~~Load-all-cmdlets-locally.ps1"

$adf = Import-AdfFromFolder -FactoryName $script:DataFactoryName -RootFolder "$RootFolder"
$adf.ResourceGroupName = "$ResourceGroupName";
$adf 

$triggersADF = Get-SortedTriggers -DataFactoryName $adf.Name -ResourceGroupName $adf.ResourceGroupName
$triggersADF
#$triggerNames = $adf.Triggers | ForEach-Object {$_.name} | ToArray
#$triggersToStop = $triggerNames | Where-Object { ($triggersADF | Select-Object name).name -contains $_ } | ToArray
$triggersToStop = $triggersADF | Where-Object { $_.RuntimeState -ne "Stopped" } | ToArray
$triggersToStop
$triggersToStop.GetType()
$triggersToStop[0].Name

$triggersToStop | ForEach-Object { 
    Write-host "- Disabling trigger: $($_.Name)" 
    Write-Host $_.Name
}


# Get

$adfSource = Import-AdfFromFolder -FactoryName "$DataFactoryName" -RootFolder "$RootFolder"
$adfIns = Get-AdfFromService -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
$adfTargetObj = $adfIns.DataFlows[0]

$adfSource.AllObjects().Count
$adfIns.AllObjects().Count

$i=1
$adfIns.AllObjects() | ForEach-Object {
    $sn = $_.Name
    $src = $adfSource.AllObjects() | Where-Object { $_.Name -eq $sn }
    Write-Host "$i) $sn    =    $($src.Name)"
    $i++
}

Write-Host "Ins:"
$adfIns.AllObjects() | ForEach-Object {
    Write-Host "$($_.Name)"
}
Write-Host "Src:"
$adfSource.AllObjects() | ForEach-Object {
    Write-Host "$($_.Name)"
}

$adfIns.AllObjects() | Where-Object { $_.name -eq "LS_AzureKeyVault" }
$adfSource.AllObjects() | Where-Object { $_.name -eq "LS_AzureKeyVault" }



Remove-AdfObjectIfNotInSource -adfSource $adfSource -adfTargetObj $adfTargetObj -adfInstance $adfIns

$adfTargetObj = $adfIns.AllObjects() | Where-Object { $_.Name -eq 'DS_BadgesDataRelay' }
$refobj = $adfTargetObj
Remove-AdfObject -obj $refobj -adfInstance $adfInstance


$adfIns.AllObjects() | ForEach-Object {
    Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $_ -adfInstance $adfIns
}

$adfTargetObj = ($adfIns.AllObjects() | Where-Object { $_.name -eq "LS_AzureKeyVault" })[0]
Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $adfTargetObj -adfInstance $adfIns
$adfTargetObj = ($adfIns.AllObjects() | Where-Object { $_.name -eq "LS_AzureKeyVault" })[1]
Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $adfTargetObj -adfInstance $adfIns





$adfSource = Import-AdfFromFolder -FactoryName "$DataFactoryName" -RootFolder "$RootFolder"
$adfIns = Get-AdfFromService -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"

$adfTargetObj = ($adfIns.AllObjects() | Where-Object { $_.name -eq "pipeline2" })[0]
$adfTargetObj
Remove-AdfObjectIfNotInSource -adfSource $adfSource -adfTargetObj $adfTargetObj -adfInstance $adfIns




#TODO: provide function to delete listed objects


