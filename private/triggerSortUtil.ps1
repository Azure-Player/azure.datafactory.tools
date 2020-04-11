function triggerSortUtil {
    param([Microsoft.Azure.Commands.DataFactoryV2.Models.PSTrigger]$trigger,
    [Hashtable] $triggerNameResourceDict,
    [Hashtable] $visited,
    [System.Collections.Stack] $sortedList)

    if ($visited[$trigger.Name] -eq $true) {
        return;
    }
    $visited[$trigger.Name] = $true;
    # $trigger.Properties.DependsOn `
    # | Where-Object {$_ -and $_.ReferenceTrigger} `
    # | ForEach-Object {
    #     triggerSortUtil `
    #     -trigger $triggerNameResourceDict[$_.ReferenceTrigger.ReferenceName] `
    #     -triggerNameResourceDict $triggerNameResourceDict `
    #     -visited $visited `
    #     -sortedList $sortedList
    # }
    $sortedList.Push($trigger)
}
