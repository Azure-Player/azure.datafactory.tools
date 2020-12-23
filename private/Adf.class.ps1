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
    [string] $Location = ""
    [AdfGlobalProp] $GlobalFactory = [AdfGlobalProp]::new()
    [AdfPublishOption] $PublishOptions

    [System.Collections.ArrayList] AllObjects()
    {
        return $this.LinkedServices + $this.Pipelines + $this.DataSets + $this.DataFlows + $this.Triggers + $this.IntegrationRuntimes + $this.Factories
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

