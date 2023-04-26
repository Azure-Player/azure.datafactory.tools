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
    [System.Collections.ArrayList] $Credentials = @{}

    [System.Collections.ArrayList] AllObjects()
    {
        return $this.LinkedServices + $this.Pipelines + $this.DataSets + $this.DataFlows + $this.Triggers + $this.IntegrationRuntimes + $this.Credentials
    }
}
