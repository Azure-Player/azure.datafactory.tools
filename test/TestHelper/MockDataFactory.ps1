class MockTargetAdf {
    [string] $Name = ""
    [string] $ResourceGroupName = ""
    [string] $Location = ""

    [System.Collections.ArrayList] $_Objects = @{}

    [System.Collections.ArrayList] AllObjects()
    {
        return $this._Objects
    }

    [string] DataFactoryName()
    {
        return $($this.Name)
    }

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
            $this._Objects.Add($o) | Out-Null
        }
    }

    RemoveObject([string] $pattern)
    {
        [System.Collections.ArrayList] $n = @{}
        $this._Objects | ForEach-Object {
            $oname = $_.FullName($false);
            if (!($oname -like $pattern)) { 
                $n.Add($_) | Out-Null 
            }
        }
        $this._Objects = $n;
    }

    [bool] IsExist($fullName)
    {
        $is_exists = $this.GetObjectByFullName($fullName)
        return !($null -eq $is_exists)
    }

    [PsObject] GetObjectByFullName([string] $pattern)
    {
        $r = $null
        $this._Objects | ForEach-Object {
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
        $this._Objects | ForEach-Object {
            $oname = $_.FullName($false);
            if ($oname -like $pattern) { 
                $r.Add($_)
            }
        }
        return $r
    }

}

