Param(
    [Parameter(Mandatory)]
    [string]$folder,

    [Parameter(Mandatory=$false)]
    [string]$TestFilenameFilter = "*",

    [Parameter(Mandatory=$false)]
    [Switch]$MajorRelease
)

Write-Host "Host Name: $($Host.name)"

$rootPath = Switch ($Host.name) {
	'Visual Studio Code Host' { split-path $psEditor.GetEditorContext().CurrentFile.Path }
	'Windows PowerShell ISE Host' { Split-Path -Path $psISE.CurrentFile.FullPath }
	'ConsoleHost' { $PSScriptRoot }
}
# $folder = $rootPath;
# $MajorRelease = $false
# $TestFilenameFilter = "*"

Write-Host "Setting new location: $testFolder"
Push-Location "$testFolder"
Get-Location | Out-Host


# Add the module location to the value of the PSModulePath environment variable
#$p = [Environment]::GetEnvironmentVariable("PSModulePath")
#$p += ";$folder"
#[Environment]::SetEnvironmentVariable("PSModulePath", $p)

Get-PSRepository

Write-Host "Installing PS modules..."
# Set a process scoped flag so we can run tests while developing without waiting for modules to load again
if ($null -eq [Environment]::GetEnvironmentVariable("azure.datafactory.tools.unitTestInstalledModules", 'Process')){
    [Environment]::SetEnvironmentVariable("azure.datafactory.tools.unitTestInstalledModules", $false, 'Process');
}
if ([Environment]::GetEnvironmentVariable("azure.datafactory.tools.unitTestInstalledModules", 'Process') -eq $false){
    Install-Module 'Az.DataFactory' -Force -MinimumVersion 1.8.0 -Repository 'PSGallery'
    Install-Module 'PSScriptAnalyzer' -Force
    Install-Module 'Pester' -Force -MinimumVersion 5.1.1
    Import-Module 'Pester'
    Import-Module 'PSScriptAnalyzer'
    Import-Module "$folder\..\azure.datafactory.tools.psd1"
    [Environment]::SetEnvironmentVariable("azure.datafactory.tools.unitTestInstalledModules", $true, 'Process');
}
Write-Host "=============== Modules ================"
Get-Module | Out-Host

try {
    $r = $null
    $VerbosePreference = 'SilentlyContinue'
    $ErrorActionPreference = 'Stop'     #Important!!!

    #Set-Location "X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test"
    $configuration = [PesterConfiguration]::Default
    $configuration.Run.Exit = $true
    $configuration.Should.ErrorAction = 'Continue'
    $configuration.CodeCoverage.Enabled = $false
    $configuration.TestResult.OutputFormat = "NUnitXml"
    $configuration.TestResult.OutputPath = "$folder\TEST-Results.xml"
    $configuration.TestResult.Enabled = $true
    $configuration.Output.Verbosity = 'Detailed'
    if ($MajorRelease -eq $false) {
        $configuration.Filter.ExcludeTag = 'Integration'
    }
    $configuration.Run.Path = "$folder"
    $configuration.Run.TestExtension = "$TestFilenameFilter.Tests.ps1"
    $configuration.Run.PassThru = $true
    $r = Invoke-Pester -Configuration $configuration
    $r.Result

    #$r.Failed
    #$r.Passed[0]
    $r.Failed | Format-Table -Property Result, StartLine, Duration, Path

    #Get-ChildItem -Path $folder | Format-Table

} finally {
    Pop-Location
}