$Path = '.'
$ScriptAnalyzerRules = Get-ScriptAnalyzerRule -Severity 'Error'
$ScriptAnalyzerResult = Invoke-ScriptAnalyzer -Path $Path -Recurse -IncludeRule $ScriptAnalyzerRules

$ScriptAnalyzerResult | Format-Table -AutoSize
$ScriptAnalyzerResult.Length

## Get-Module 'PsScriptAn*'
