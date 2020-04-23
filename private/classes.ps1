class Adf {
    [string] $Name = ""
    [string] $ResourceGroupName = ""
    [System.Collections.ArrayList] $Pipelines = @{}
    [System.Collections.ArrayList] $LinkedServices = @{}
    [System.Collections.ArrayList] $DataSets = @{}
    [System.Collections.ArrayList] $DataFlows = @{}
    [System.Collections.ArrayList] $Triggers = @{}
    [System.Collections.ArrayList] $IntegrationRuntimes = @{}
    [string] $Location = ""

    [System.Collections.ArrayList] AllObjects()
    {
        return $this.LinkedServices + $this.Pipelines + $this.DataSets + $this.DataFlows + $this.Triggers + $this.IntegrationRuntimes
    }
}

class AdfObject {
    [string] $Name
    [string] $Type
    [string] $FileName
    [System.Collections.Hashtable] $DependsOn = @{}
    [Boolean] $Deployed = $false
    [Adf] $Adf
    [PSCustomObject] $Body

    [Boolean] AddDependant ([string]$name, [string]$type)
    {
        $type2 = $type.Replace('Reference', '')
        if (!$this.DependsOn.ContainsKey($name)) {
            $this.DependsOn.Add( $name, $type2 ) | Out-Null
        }
        return $true
    }
}

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
        return $this.LinkedServices + $this.Pipelines + $this.DataSets + $this.DataFlows + $this.Triggers + $this.IntegrationRuntimes
    }
}
