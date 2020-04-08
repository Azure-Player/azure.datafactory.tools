function Import-AdfObjects {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] $Adf,
        [parameter(Mandatory = $true)] $All,
        [parameter(Mandatory = $true)] [String] $RootFolder,
        [parameter(Mandatory = $true)] [String] $SubFolder,
        [parameter(Mandatory = $false)] [String] $AzureType
    )

    Write-Verbose "Analyzing $AzureType dependencies..."
    #$All = @{}
    $folder = Join-Path $RootFolder "$SubFolder"
    Write-Verbose "$folder"
    Get-ChildItem "$folder" -Filter "*.json" | 
    Foreach-Object {
        Write-Verbose "- $($_.Name)"
        $txt = get-content $_.FullName
        #$json = $txt | ConvertFrom-Json
        $o = New-Object -TypeName AdfObject 
        $o.Name = $_.BaseName
        $o.Type = $AzureType   #$json.type
        $o.FileName = $_.FullName
        # $o = [AdfObject]@{
        #     Name = $_.BaseName
        #     Type = $AzureType   #$json.type
        # }
        $m = [regex]::matches($txt,'"referenceName": ?"(?<v>.+?)"')
        $m | ForEach-Object {
            $o.DependsOn.Add($_.Groups['v'].Value)
        }
        #$All.Add($_.BaseName, $o)
        $o.Adf = $Adf
        $All.Add($o)
        Write-Verbose ("- {0} : found {1} dependencies." -f $_.BaseName, $o.DependsOn.Count)
    }

    #return $All
    #return (,$All)
    #return Write-Output -NoEnumerate $All

}