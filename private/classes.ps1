class Adf {
    [string] $Name = ""
    [string] $ResourceGroupName = ""
    [System.Collections.ArrayList] $Pipelines = @{}
    [System.Collections.ArrayList] $LinkedServices = @{}
    [System.Collections.ArrayList] $DataSets = @{}
    [string] $Location = ""

    [System.Collections.ArrayList] AllObjects()
    {
        return $this.LinkedServices + $this.Pipelines + $this.DataSets
    }
}

class AdfObject {
    [string] $Name
    [string] $Type
    [string] $FileName
    [System.Collections.ArrayList] $DependsOn = @{}
    [Boolean] $Deployed = $false
    [Adf] $Adf
}

