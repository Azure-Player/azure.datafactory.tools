
$file = (Join-Path -Path $RootFolder -ChildPath "trigger") | Join-Path -ChildPath "$triggerName.json"
#The function below doesn't execute mocked functions (Get-AzDataFactoryV2Trigger), so we have to call them directly
#Publish-TriggerIfNotExist -Name $triggerName -FileName $file @script:CommonParam
#begin Publish-TriggerIfNotExist
$tr = Get-AzDataFactoryV2Trigger -TriggerName $triggerName @script:CommonParam  #-ErrorAction:SilentlyContinue
if ($null -eq $tr) {
    $f = $file.ToString()
    Set-AzDataFactoryV2Trigger -Name $triggerName -DefinitionFile $f @script:CommonParam
    #-Force
}
#end Publish-TriggerIfNotExist

if ($CurrentState -eq 'Enabled') { Start-TargetTrigger -Name $triggerName @script:CommonParam }
if ($CurrentState -eq 'Disabled') { Stop-TargetTrigger -Name $triggerName @script:CommonParam }
# The block below is a trick to enforce publishing a trigger, because for some reason, 
# unchanged trigger won't be published and hence doesn't have to be stopped prior publish, which fails tests B04 & B06.
# if ($triggerName) {
#     $file = Join-Path $RootFolder "trigger" "$triggerName.json" 
#     $startTime = (Get-Date -format "yyyy-MM-ddTHH:mm:ss.000Z")
#     Edit-ObjectPropertyInFile $file "properties.typeProperties.recurrence.startTime" """$startTime"""
# }

$opt = New-AdfPublishOption
$opt.TriggerStopMethod = $tsm
if ($Mode -eq 'Included') { $opt.Includes.Add("*.$triggerName", "") }
if ($Mode -eq 'Excluded') { $opt.Excludes.Add("*.*", "") }
$opt.StopStartTriggers = $StopStartTriggers
$opt.DoNotStopStartExcludedTriggers = $DoNotStopStartExcludedTriggers
$opt.DeleteNotInSource = $DeleteNIS

$ExpectDisableTrigger = $StopStartTriggers -and $CurrentState -eq 'Enabled'
[AdfObjectName] $oname = [AdfObjectName]::new("trigger.$triggerName")
$IsMatchExcluded = $oname.IsNameMatch($opt.Excludes.Keys)
$ExpectDisableTrigger = $ExpectDisableTrigger -and -not ( $IsMatchExcluded -and $opt.DoNotStopStartExcludedTriggers )

if ($ShouldThrow) {
    { Publish-AdfV2FromJson -RootFolder "$RootFolder" `
    -ResourceGroupName "$ResourceGroupName" `
    -DataFactoryName "$DataFactoryName" `
    -Location "$Location" -Option $opt -Stage $stage
    } | Should -Throw
} else {
    { Publish-AdfV2FromJson -RootFolder "$RootFolder" `
    -ResourceGroupName "$ResourceGroupName" `
    -DataFactoryName "$DataFactoryName" `
    -Location "$Location" -Option $opt -Stage $stage
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