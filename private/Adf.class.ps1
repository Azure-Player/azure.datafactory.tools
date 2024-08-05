class AdfGlobalProp {
    [string] $FilePath = ""
    [string] $body = ""
    [PSCustomObject] $GlobalParameters
}

class Adf {
    [string] $Name = ""
    [string] $ResourceGroupName = ""
    [string] $Region = ""
    [System.Collections.ArrayList] $Pipelines = @{}
    [System.Collections.ArrayList] $LinkedServices = @{}
    [System.Collections.ArrayList] $DataSets = @{}
    [System.Collections.ArrayList] $DataFlows = @{}
    [System.Collections.ArrayList] $Triggers = @{}
    [System.Collections.ArrayList] $IntegrationRuntimes = @{}
    [System.Collections.ArrayList] $Factories = @{}
    [System.Collections.ArrayList] $ManagedVirtualNetwork = @{}
    [System.Collections.ArrayList] $ManagedPrivateEndpoints = @{}
    [System.Collections.ArrayList] $Credentials = @{}
    [string] $Location = ""
    [AdfGlobalProp] $GlobalFactory = [AdfGlobalProp]::new()
    [AdfPublishOption] $PublishOptions
    $ArmTemplateJson
    [System.Collections.ArrayList] $ActiveTriggers = @{}       # List of "started" triggers before deployment. Populated only when StartStopTriggers=True 
    [System.Collections.ArrayList] $StoppedTriggerNames = @{}  # List of triggers have been stopped by "Stop-Triggers" cmdlet
    [System.Collections.ArrayList] $TargetTriggerNames = @{}   # List of all triggers in target instance of ADF. Populated only when StartStopTriggers=True 
    [System.Collections.ArrayList] $DeletedObjectNames = @{}

    [System.Collections.ArrayList] AllObjects()
    {
        return $this.LinkedServices + $this.Pipelines + $this.DataSets + $this.DataFlows + $this.Triggers + $this.IntegrationRuntimes + $this.Factories + $this.ManagedVirtualNetwork + $this.ManagedPrivateEndpoints + $this.Credentials
    }

    [hashtable] GetObjectsByFullName([string]$pattern)
    {
        [hashtable] $r = @{}
        $this.AllObjects() | ForEach-Object {
            $oname = $_.FullName($false);
            if ($oname -like $pattern) { 
                $null = $r.Add($oname, $_)
            }
        }
        return $r
    }

    [hashtable] GetObjectsByFolderName([string]$folder)
    {
        [hashtable] $r = @{}
        $this.AllObjects() | ForEach-Object {
            $ofn = $_.GetFolderName()
            if ($ofn -like $folder) 
            { 
                $oname = $_.FullName($false);
                $null = $r.Add($oname, $_)
            }
        }
        return $r
    }

    [Boolean] IsObjectDeleted([string] $ObjectName)
    {
        return $this.DeletedObjectNames -contains $ObjectName
    }

    [Boolean] HasTriggerBeenStopped([string] $ObjectName)
    {
        return $this.StoppedTriggerNames -contains $ObjectName
    }

    [Boolean] IsTargetTriggerStarted([string] $ObjectName)
    {
        $o = $this.TargetTriggerNames | Where-Object { $_.Name -eq $ObjectName }
        return $null -ne $o -and $o.RuntimeState -eq 'Started'
    }

    SetTargetTriggerNames($allAdfTriggersArray) 
    {
        # Clone triggers with selected properties
        $this.TargetTriggerNames.Clear()
        $allAdfTriggersArray | ForEach-Object {
            $trigger = $_
            $clonedTrigger = [PSCustomObject]@{
                Name = $trigger.Name
                RuntimeState = $trigger.RuntimeState
            }
            $this.TargetTriggerNames.Add($clonedTrigger) | Out-Null
        }
    }

    [System.Collections.ArrayList] GetUnusedDatasets()
    {
        [System.Collections.ArrayList] $dataset_list = @{}
        $this.DataSets | ForEach-Object { $null = $dataset_list.Add("$($_.Type.ToLower()).$($_.Name)") }

        # Collect all objects used by pipelines and dataflows
        $list = $this.Pipelines + $this.DataFlows
        if ($list.Count -gt 0) { 
            $list = $list.DependsOn

            # Filter list to datasets only
            $used = $list | Where-Object { $_.StartsWith('dataset.', "CurrentCultureIgnoreCase") } | `
                            ForEach-Object { $_.Substring(8).Insert(0, 'dataset.') } | `
                            Select-Object -Unique

            # Remove all used datasets from $dataset_list
            $used | ForEach-Object { $dataset_list.Remove($_) }
        }

        # datasets not removed from the list are the ones not being used
        return $dataset_list
    }   


}

