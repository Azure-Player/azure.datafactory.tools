class AdfGlobalProp {
    [string] $FilePath = ""
    [string] $body = ""
    [PSCustomObject] $GlobalParameters
}

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
    [AdfGlobalProp] $GlobalFactory = [AdfGlobalProp]::new()

    [System.Collections.ArrayList] AllObjects()
    {
        return $this.LinkedServices + $this.Pipelines + $this.DataSets + $this.DataFlows + $this.Triggers + $this.IntegrationRuntimes
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
            if ($ofn -eq $folder) 
            { 
                $oname = $_.FullName($false);
                $null = $r.Add($oname, $_)
            }
        }
        return $r
    }

}

