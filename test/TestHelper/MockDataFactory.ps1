class MockTargetAdf {
    [string] $Name = ""
    [string] $ResourceGroupName = ""
    [string] $Location = ""
    #[hashtable] $AllObjects = @{}

    #[System.Collections.ArrayList] $Triggers = @{}
    [System.Collections.ArrayList] $AllObjects = @{}


    DeployObject($o)
    {
        $fullName = "$($o.type).$($o.name)"
        $is_exists = $this.IsExist($fullName)
        if ($is_exists) {
            $tt = $this.GetObjectByFullName($fullName)
            if ($tt.RuntimeState -eq 'Started' -and $o.type -like "*trigger*") {
                throw ("ADF simulation: Can't deploy trigger because its Started.")
            }
        } else {
            $this.AllObjects.Add($o) | Out-Null
        }
    }

    RemoveObject($fullName)
    {
        [System.Collections.ArrayList] $n = @{}
        $this.AllObjects | ForEach-Object {
            if (!($_.Name -like $fullName)) { $n.Add($_) | Out-Null }
        }
        $this.AllObjects = $n;
    }

    [bool] IsExist($fullName)
    {
        $is_exists = $this.GetObjectByFullName($fullName)
        return !($null -eq $is_exists)
    }

    [PsObject] GetObjectByFullName([string] $pattern)
    {
        $r = $null
        $this.AllObjects | ForEach-Object {
            $oname = $_.FullName($false);
            if ($oname -like $pattern) { 
                $r = $_
            }
        }
        return $r
    }

    [System.Collections.ArrayList] GetObjectsByFullName([string] $pattern)
    {
        [System.Collections.ArrayList] $r = @{}
        $this.AllObjects | ForEach-Object {
            $oname = $_.FullName($false);
            if ($oname -like $pattern) { 
                $r.Add($_)
            }
        }
        return $r
    }

}

