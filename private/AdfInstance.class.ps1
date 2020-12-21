class AdfInstance {
    [string] $Id = ""
    [string] $Name = ""
    [string] $ResourceGroupName = ""
    [string] $Location = ""
    [System.Collections.ArrayList] $Pipelines = @{}
    [System.Collections.ArrayList] $LinkedServices = @{}
    [System.Collections.ArrayList] $DataSets = @{}
    [System.Collections.ArrayList] $DataFlows = @{}
    [System.Collections.ArrayList] $Triggers = @{}
    [System.Collections.ArrayList] $IntegrationRuntimes = @{}

    [System.Collections.ArrayList] AllObjects()
    {
        return $this.Triggers + $this.Pipelines + $this.DataFlows + $this.DataSets + $this.LinkedServices + $this.IntegrationRuntimes
    }
}
