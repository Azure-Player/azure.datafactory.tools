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
        $this.DataSets | ForEach-Object
        {
            $null = $dataset_list.Add($_.Name) 
        }
        # iterate over pipelines and dataflows content looking for dataset names
        foreach ($pipe in $this.Pipelines.FileName + $this.DataFlows.FileName)
        {
            $stringContent = Get-Content $pipe
            For ($i=0; $i -lt $dataset_list.Count; $i++) 
            {
                # if the dataset is being used, replace it with ''
                if ($stringContent -match $dataset_list[$i])
                {
                    $dataset_list[$i] = ''
                }
            }
            # remove used datasets from the list, try will fail with the last object
            # so it goes to the catch when cleaning the list.
            Try 
            {
                $dataset_list = ( $dataset_list | Where-Object { $_ -ne '' } )
            }
            Catch 
            {
                $dataset_list.Remove('')
            }
        }
        # datasets not removed from the list are the ones not being used
        return $dataset_list
    }   


}

