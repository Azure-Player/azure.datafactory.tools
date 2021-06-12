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

    [Boolean] IsNameExcluded ([AdfPublishOption] $opt)
    {
        $fullname = $this.FullNameWithFolder()

        # One can exclude objects by listing them explicitly in Excludes collection, ...
        $excPatterns = $opt.Excludes.Keys
        $r = $excPatterns | Where-Object { $fullname -like $_ }
        if ($null -ne $r) 
        { 
            # Means: object is excluded if matches any item in (Excludes) collection
            return $true    
        }

        # ... or by listing them implicitly in Includes collection:
        $incPatterns = $opt.Includes.Keys
        if ($incPatterns.Count -eq 0) 
        { 
            # If no items = all objects match => object is not excluded
            return $false 
        }
        $r = $incPatterns | Where-Object { $fullname -like $_ }
        # Means: object is excluded if not match any item in (Includes) collection
        return ($null -eq $r)   
    }

}
