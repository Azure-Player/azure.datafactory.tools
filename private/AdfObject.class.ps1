class AdfObject {
    [string] $Name
    [string] $Type
    [string] $FileName
    [System.Collections.Hashtable] $DependsOn = @{}
    [Boolean] $Deployed = $false
    [Boolean] $ToBeDeployed = $true
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

    [String] FullName ([boolean] $quoted)
    {
        $simtype = Get-SimplifiedType -Type $this.Type
        if ($quoted) {
            return "[$simtype].[$($this.Name)]"
        } else {
            return "$simtype.$($this.Name)"
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

    [String] GetFolderName()
    {
        $o = $this.Body.properties
        $ofn = $null
        if ($o.PSobject.Properties.Name -contains "folder")
        {
            $ofn = $_.Body.properties.folder.name
        }
        return $ofn
    }


}

if (!(Get-Variable ADF_FOLDERS -ErrorAction:SilentlyContinue)) {
    Set-Variable ADF_FOLDERS -option ReadOnly -value ('integrationRuntime', 'pipeline', 'dataset', 'dataflow', 'linkedService', 'trigger')
}    
