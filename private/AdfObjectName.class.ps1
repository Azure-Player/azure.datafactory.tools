class AdfObjectName {
    [string] $Name
    [string] $Type
    [string] $Folder

    AdfObjectName ([string] $Name, [string] $Type) 
    {
        [AdfObject]::AssertType($Type)
        $this.Name = $Name
        $this.Type = $Type
    }

    AdfObjectName ([string] $Name, [string] $Type, [string] $Folder) 
    {
        [AdfObject]::AssertType($Type)
        $this.Name = $Name
        $this.Type = $Type
        $this.Folder = $Folder
    }

    AdfObjectName ([string] $FullName) 
    {
        $m = [regex]::matches($FullName, '([a-zA-Z]+)\.([a-zA-Z 0-9\-_]+)@?(.*)')
        if ($m.Success -eq $false) {
            throw "ADFT0028: Expected format of name for 'FullName' input parameter is: objectType.objectName[@folderName]"
        }
        [AdfObject]::AssertType($m.Groups[1].Value)
        $this.Type = $m.Groups[1].Value
        $this.Name = $m.Groups[2].Value
        $this.Folder = $m.Groups[3].Value
    }

    [String] FullName ([boolean] $quoted)
    {
        if ($quoted) {
            return "[$($this.Type)].[$($this.Name)]"
        } else {
            return "$($this.Type).$($this.Name)"
        }
    }

    [String] FullNameWithFolder ()
    {
        if ($this.Folder.Length -gt 0) {
            return "$($this.Type).$($this.Name)@$($this.Folder)"
        } else {
            return "$($this.Type).$($this.Name)"
        }
    }

    [String] FullName ()
    {
        return $this.FullName($false)
    }

    [String] FullNameQuoted ()
    {
        return $this.FullName($true)
    }

    [Boolean] IsNameMatch ([array]$wildcardPatterns)
    {
        $fullname = $this.FullName()
        $r = $wildcardPatterns | Where-Object { $fullname -like $_ }
        return $null -ne $r
    }

    # Same rule semantics as AdfObject.IsNameMatch: 'type.name[@folder]', folder is checked only when the rule has one
    [Boolean] IsRuleMatch ([string] $rule)
    {
        $arr = $rule.Split('@')
        $r = $this.FullName() -like $arr[0]
        if ($arr.Count -gt 1) {
            $r = $r -and ($this.Folder -like $arr[1])
        }
        return $r
    }

    [Boolean] IsNameExcluded ([AdfPublishOption] $opt)
    {
        # One can exclude objects by listing them explicitly in Excludes collection, ...
        foreach ($rule in $opt.Excludes.Keys) {
            # Means: object is excluded if matches any item in (Excludes) collection
            if ($this.IsRuleMatch($rule)) { return $true }
        }

        # ... or by listing them implicitly in Includes collection:
        if ($opt.Includes.Keys.Count -eq 0)
        {
            # If no items = all objects match => object is not excluded
            return $false
        }
        foreach ($rule in $opt.Includes.Keys) {
            if ($this.IsRuleMatch($rule)) { return $false }
        }
        # Means: object is excluded if not match any item in (Includes) collection
        return $true
    }

}
