
if ($CurrentState -eq 'Enabled') { Start-TargetTrigger -Name $triggerName @script:CommonParam }
if ($CurrentState -eq 'Disabled') { Stop-TargetTrigger -Name $triggerName @script:CommonParam }
# The block below is a trick to enforce publishing a trigger, because for some reason, 
# unchanged trigger won't be published and hence doesn't have to be stopped prior publish, which fails tests B04 & B06.
$file = Join-Path $RootFolder "trigger" "$triggerName.json" 
$startTime = (Get-Date -format "yyyy-MM-ddTHH:mm:ss.000Z")
Edit-ObjectPropertyInFile $file "properties.typeProperties.recurrence.startTime" """$startTime"""

$opt = New-AdfPublishOption
$opt.TriggerStopMethod = $tsm
if ($Mode -eq 'Included') { $opt.Includes.Add("*.$triggerName", "") }
if ($Mode -eq 'Excluded') { $opt.Excludes.Add("*.*", "") }
$opt.StopStartTriggers = $StopStartTriggers
$opt.DoNotStopStartExcludedTriggers = $DoNotStopStartExcludedTriggers

$ExpectDisableTrigger = $StopStartTriggers -and $CurrentState -eq 'Enabled'
[AdfObjectName] $oname = [AdfObjectName]::new("trigger.$triggerName")
$IsMatchExcluded = $oname.IsNameMatch($opt.Excludes.Keys)
$ExpectDisableTrigger = $ExpectDisableTrigger -and -not ( $IsMatchExcluded -and $opt.DoNotStopStartExcludedTriggers )

if ($ShouldThrow) {
    { Publish-AdfV2FromJson -RootFolder "$RootFolder" `
    -ResourceGroupName "$ResourceGroupName" `
    -DataFactoryName "$DataFactoryName" `
    -Location "$Location" -Option $opt -Stage "trigger-$DesiredState"
    } | Should -Throw
} else {
    { Publish-AdfV2FromJson -RootFolder "$RootFolder" `
    -ResourceGroupName "$ResourceGroupName" `
    -DataFactoryName "$DataFactoryName" `
    -Location "$Location" -Option $opt -Stage "trigger-$DesiredState"
    } | Should -Not -Throw
}

Assert-MockCalled Stop-Trigger -Times ([int]$ExpectDisableTrigger)

$script:TriggersOnDiskCount = (Get-ChildItem -Path "$RootFolder\trigger" -Filter "$triggerName.json" -Recurse:$true | Measure-Object).Count
$tr = Get-AzDataFactoryV2Trigger @script:CommonParam
$arr = $tr | ToArray
$script:TriggersInServiceCount = $arr.Count
$script:TriggersInServiceCount | Should -Be $TrExistsAfter
if ($TrExistsAfter -eq 1)
{
    $arr[0].RuntimeState | Should -Be (ConvertTo-RuntimeState $StateAfter)
}