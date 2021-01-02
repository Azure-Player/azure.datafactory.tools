class AdfObjectName {
    [string] $Name
    [string] $Type

    AdfObjectName ([string] $Name, [string] $Type) 
    {
        $this.Name = $Name
        $this.Type = $Type
    }

    AdfObjectName ([string] $FullName) 
    {
        if ($FullName.IndexOf('.') -lt 1) {
            Write-Error "Expected format of name for 'FullName' input parameter is: objectType.objectName"
        }
        $parts = $FullName.Split('.')
        if ($parts[0] -notin [AdfObject]::allowedTypes ) { 
            Write-Error -Message "Unknown object type: $parts[0]."
        }
        $this.Type = $parts[0]
        $this.Name = $parts[1]
    }

    [String] FullName ([boolean] $quoted)
    {
        if ($quoted) {
            return "[$($this.Type)].[$($this.Name)]"
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

}
