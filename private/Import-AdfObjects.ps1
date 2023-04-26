function Import-AdfObjects {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] $Adf,
        [parameter(Mandatory = $true)] $All,
        [parameter(Mandatory = $true)] [String] $RootFolder,
        [parameter(Mandatory = $true)] [String] $SubFolder
    )

    Write-Verbose "Analyzing $SubFolder dependencies..."

    $folder = Join-Path $RootFolder "$SubFolder"
    if (-Not (Test-Path -Path "$folder" -ErrorAction Ignore))
    {
        Write-Verbose "Folder: '$folder' does not exist. No objects to be imported."
        return
    }

    Write-Verbose "Folder: $folder"
    Get-ChildItem "$folder" -Filter "*.json" | Where-Object { !$_.Name.StartsWith('~') } |
    Foreach-Object {
        Write-Verbose "- $($_.Name)"
        $txt = Get-Content $_.FullName -Encoding "UTF8"
        $o = New-Object -TypeName "AdfObject"
        $o.Name = $_.BaseName
        $o.Type = $SubFolder
        $o.FileName = $_.FullName
        $o.Body = $txt | ConvertFrom-Json

        # Set Global Parameters
        if ($SubFolder -eq 'factory') {
            $adf.GlobalFactory.FilePath = $_.FullName
            $adf.GlobalFactory.body = $txt
            Set-StrictMode -Version 1
            $adf.GlobalFactory.GlobalParameters = $o.Body.Properties.globalParameters
        }

        # Discover all referenced objects
        $refs = Get-ReferencedObjects -obj $o
        foreach ($r in $refs) {
            $oname = [AdfObjectName]::new($r)
            $o.AddDependant( $oname.Name, $oname.Type )
        }

        $o.Adf = $Adf
        $All.Add($o)
        Write-Verbose ("- {0} : found {1} dependencies." -f $_.BaseName, $o.DependsOn.Count)
    }

}