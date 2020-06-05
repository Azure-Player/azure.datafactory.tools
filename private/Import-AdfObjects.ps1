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
        $o = New-Object -TypeName AdfObject 
        $o.Name = $_.BaseName
        $o.Type = $SubFolder
        $o.FileName = $_.FullName
        $o.Body = $txt | ConvertFrom-Json
        $m = [regex]::matches($txt,'"referenceName":\s*?"(?<r>.+?)",[\n\r\s]+"type":\s*?"(?<t>.+?)"')
        $m | ForEach-Object {
            $o.AddDependant( $_.Groups['r'].Value, $_.Groups['t'].Value ) | Out-Null
        }
        $o.Adf = $Adf
        $All.Add($o)
        Write-Verbose ("- {0} : found {1} dependencies." -f $_.BaseName, $o.DependsOn.Count)
    }

}