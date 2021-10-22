Param(
    [Parameter(Mandatory)]
    [string]$folder,

    [Parameter(Mandatory=$false)]
    [string]$TestFilenameFilter = "*",

    [Parameter(Mandatory=$false)]
    [Switch]$LocalTestsOnly
)
# $folder = 'X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test'

Write-Host "Setting new location: $folder"
Push-Location "$folder"
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
    Import-Module 'Az.DataFactory'
    Import-Module "$folder\azure.datafactory.tools.psd1"
    [Environment]::SetEnvironmentVariable("azure.datafactory.tools.unitTestInstalledModules", $true, 'Process');
}
Get-Module | Out-Host

#v4
#Invoke-Pester -Script "$folder\test\*.Tests.ps1" -EnableExit -OutputFile "TEST-Results.xml" -OutputFormat NUnitXml

#v4
#Invoke-Pester -Script "$testFile" -EnableExit -OutputFile "TEST-Results.xml" -OutputFormat NUnitXml

#v5
#cls
try{
    $r = $null
    $VerbosePreference = 'SilentlyContinue'
    $ErrorActionPreference = 'Continue'     #Important!!!

    #Set-Location "X:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\test"
    $configuration = [PesterConfiguration]::Default
    $configuration.Run.Exit = $true
    $configuration.Should.ErrorAction = 'Continue'
    $configuration.CodeCoverage.Enabled = $false
    $configuration.TestResult.OutputFormat = "NUnitXml"
    $configuration.TestResult.OutputPath = "TEST-Results.xml"
    $configuration.TestResult.Enabled = $true
    $configuration.Output.Verbosity = 'Detailed'
    if ($LocalTestsOnly) {
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