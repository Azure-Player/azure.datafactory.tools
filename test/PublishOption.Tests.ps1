[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
[CmdletBinding()]
param
(
    [Parameter()]
    [System.String]
    $ModuleRootPath = (Get-Location)
)

$moduleManifestName = 'azure.datafactory.tools.psd1'
$moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

Import-Module -Name $moduleManifestPath -Force -Verbose:$false

InModuleScope azure.datafactory.tools {
    #$testHelperPath = $PSScriptRoot | Split-Path -Parent | Join-Path -ChildPath 'TestHelper'
    #Import-Module -Name $testHelperPath -Force

    # Variables for use in tests

    Describe 'New-AdfPublishOption' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name New-AdfPublishOption -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'When called' {
            It 'Should return object of AdfPublishOption type' {
                $script:result = New-AdfPublishOption
                $script:result.GetType() | Should -Be 'AdfPublishOption'
            }
            It 'Should contains Includes prop as hashtable with no items' {
                $script:result.Includes.GetType() | Should -Be 'hashtable'
                $script:result.Includes.Count | Should -Be 0
            }
            It 'Should contains Excludes prop as hashtable with no items' {
                $script:result.Excludes.GetType() | Should -Be 'hashtable'
                $script:result.Excludes.Count | Should -Be 0
            }
            It 'Should contains additional properties with default values set' {
                $script:result.DeleteNotInSource | Should -Be $false
                $script:result.StopStartTriggers | Should -Be $true
            }

        }
        
    } 
}
