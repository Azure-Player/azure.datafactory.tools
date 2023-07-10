<#
.SYNOPSIS
Creates an instance of objects with options for publishing ADF.

.DESCRIPTION
Creates an instance of objects with options for publishing ADF.
Use it if you want specify particular behaviour during publish operation.

.PARAMETER FilterFilePath
Optional path to file which contains all filtering rules in multiline file (one line per rule).
When provided, the function adds items to appropriate array (Includes or Excludes).
Do use + or - character as a prefix of name to control where the rule should be added to.

.EXAMPLE
$opt = New-AdfPublishOption
$opt.Includes.Add("pipeline.Copy*", "")
$opt.DeleteNotInSource = $false
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Stage "UAT" -Option $opt

.EXAMPLE
$opt = New-AdfPublishOption
$opt.DeleteNotInSource = $false
$opt.StopStartTriggers = $false
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Stage "UAT" -Option $opt

.EXAMPLE
$opt = New-AdfPublishOption -FilterFilePath ".\deployment\rules.txt"
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Stage "UAT" -Option $opt

.LINK
Online version: https://github.com/SQLPlayer/azure.datafactory.tools/
#>
function New-AdfPublishOption {
    [CmdletBinding()]
    param (   
        [parameter(Mandatory = $false)] 
        [String] $FilterFilePath
    )

    $opt = New-Object -TypeName AdfPublishOption

    if (![string]::IsNullOrWhitespace($FilterFilePath)) {
        Write-Verbose "Loading rules for selective deployment from file '$FilterFilePath'..."
        if ($false -eq (Test-Path -Path $FilterFilePath)) {
            Write-Error "ADFT0026: File does not exist: $FilterFilePath"
        }
        $FilterText = Get-Content -Path $FilterFilePath -Encoding "UTF8"
        if ($null -eq $FilterText) { $FilterText = '' }

        $FilterArray = $FilterText.Replace(',', "`n").Replace("`r`n", "`n").Split("`n");

        # Include/Exclude options
        $FilterArray | Where-Object { ($_.Trim().Length -gt 0 -or $_.Trim().StartsWith('+')) -and (!$_.Trim().StartsWith('-')) } | ForEach-Object {
            $i = $_.Trim().Replace('+', '')
            Write-Verbose "- Include: $i"
            $opt.Includes.Add($i, "");
        }
        Write-Host "$($opt.Includes.Count) rule(s)/object(s) added to be included in deployment."
        
        $FilterArray | Where-Object { $_.Trim().StartsWith('-') } | ForEach-Object {
            $e = $_.Trim().Substring(1)
            Write-Verbose "- Exclude: $e"
            $opt.Excludes.Add($e, "");
        }
        Write-Host "$($opt.Excludes.Count) rule(s)/object(s) added to be excluded from deployment."
    }

    return $opt
}
