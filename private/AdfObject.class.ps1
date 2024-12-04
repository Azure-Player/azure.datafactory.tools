class AdfObject {
    [string] $Name
    [string] $Type
    [string] $FileName
    [System.Collections.ArrayList] $DependsOn = @()
    [Boolean] $Deployed = $false
    [Boolean] $ToBeDeployed = $true
    [Adf] $Adf
    [PSCustomObject] $Body
    [string] $RuntimeState
    
    [Boolean] AddDependant ([string]$name, [string]$refType)
    {
        $objType = $refType
        if ($refType.EndsWith('Reference')) {
            $objType = $refType.Substring(0, $refType.Length-9)
        }
        [AdfObject]::AssertType($objType)
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

    [String] AzureResourceName ()
    {
        $resType = Get-AzureResourceType $this.Type
        $DataFactoryName = $this.Adf.Name
        if ($resType -like '*managedPrivateEndpoints') {
            return "$DataFactoryName/default/$($this.Name)"
        } else {
            return "$DataFactoryName/$($this.Name)"
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
            $o = $this.Body.Properties
            if ($o.PSobject.Properties -ne $null -and $o.PSobject.Properties.Name -contains "folder")
            {
                $ofn = $this.Body.Properties.folder.name
            }
        }
        return $ofn
    }

    [String] GetHash()
    {
        $hash = Get-FileHash -Path $this.FileName -Algorithm 'MD5'
        return $hash.Hash
    }

    static $AllowedTypes = @('integrationRuntime', 'pipeline', 'dataset', 'dataflow', 'linkedService', 'trigger', 'factory', 'managedVirtualNetwork', 'managedPrivateEndpoint', 'credential')
    static $IgnoreTypes  = @('notebook', 'BigDataPool', 'sparkJobDefinition')

    static AssertType ([string] $Type)
    {
        $AllTypes = [AdfObject]::AllowedTypes + [AdfObject]::IgnoreTypes
        if ($Type -notin $AllTypes ) { 
            throw "ADFT0029: Unknown object type: $Type."
        }
    }

}

if (!(Get-Variable ADF_FOLDERS -ErrorAction:SilentlyContinue)) {
    Set-Variable ADF_FOLDERS -option ReadOnly -value ([AdfObject]::AllowedTypes)
}    
