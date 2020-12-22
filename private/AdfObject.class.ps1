class AdfObject {
    [string] $Name
    [string] $Type
    [string] $FileName
    [System.Collections.ArrayList] $DependsOn = @()
    [Boolean] $Deployed = $false
    [Boolean] $ToBeDeployed = $true
    [Adf] $Adf
    [PSCustomObject] $Body

    [Boolean] AddDependant ([string]$name, [string]$refType)
    {
        $objType = $refType.Replace('Reference', '')
        $fullName = "$objType.$name"
        if (!$this.DependsOn.Contains($fullName)) {
            $this.DependsOn.Add( $fullName ) | Out-Null
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

    [Boolean] IsNameMatch ([string]$wildcardPattern)
    {
        $folder = $this.GetFolderName()
        $fullname = $this.FullName($false)
        $arr = $wildcardPattern.Split('@')
        $namePattern = $arr[0]
        if ($arr.Count -le 1)
        {
            $r = ($fullname -like $namePattern) 
        } else {
            $folderPattern = $arr[1]
            $r = ($fullname -like $namePattern) -and ( $folder -like $folderPattern )
        }
        return $r
    }

    [String] GetFolderName()
    {
        $ofn = ''
        if ($this.Body.PSObject.Properties.Name -contains "properties")
        {
            $o = $this.Body.properties
            if ($o.PSobject.Properties.Name -contains "folder")
            {
                $ofn = $this.Body.properties.folder.name
            }
        }
        return $ofn
    }

    static $AllowedTypes = @('integrationRuntime', 'pipeline', 'dataset', 'dataflow', 'linkedService', 'trigger', 'factory')

}

if (!(Get-Variable ADF_FOLDERS -ErrorAction:SilentlyContinue)) {
    Set-Variable ADF_FOLDERS -option ReadOnly -value ([AdfObject]::AllowedTypes)
}    
