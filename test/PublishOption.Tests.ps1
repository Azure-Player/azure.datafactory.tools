BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force

    # Variables for use in tests
    $script:SrcFolder = Join-Path $PSScriptRoot "BigFactorySample2"

    Describe 'New-AdfPublishOption' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name New-AdfPublishOption -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'When called without args' {
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
                $script:result.FailsWhenConfigItemNotFound | Should -Be $true
                $script:result.FailsWhenPathNotFound | Should -Be $true
            }
        }
        
        Context 'When called with wrong FilterFilePath' {
            It 'Should throw exception' {
                {
                    New-AdfPublishOption -FilterFilePath "this-file-does-not-exist.fji3ugf4.txt"
                } | Should -Throw 
            }
        }

        Context 'When called with correct FilterFilePath' {
            It 'Should not throw exception' {
                {
                    $script:opt = New-AdfPublishOption -FilterFilePath "$SrcFolder\deployment\filter.option1.txt"
                } | Should -Not -Throw 
            }
            It 'Should contains 2 rules added to Includes with appropriate values' {
                $script:opt.Includes.Count | Should -Be 2
                $script:opt.Includes.ContainsKey('pipeline.*') | Should -Be $true
                $script:opt.Includes.ContainsKey('trigger.*') | Should -Be $true
            }
            It 'Should contains 2 rules added to Excludes with appropriate values' {
                $script:opt.Excludes.Count | Should -Be 2
                $script:opt.Excludes.ContainsKey('*.SharedIR*') | Should -Be $true
                $script:opt.Excludes.ContainsKey('*.LS_SqlServer_DEV19_AW2017') | Should -Be $true
            }
        }

        Context 'When called with empty file in FilterFilePath' {
            It 'Should not throw exception' {
                {
                    $script:opt = New-AdfPublishOption -FilterFilePath "$SrcFolder\deployment\filter.empty.txt"
                } | Should -Not -Throw 
            }
            It 'Should add no rules to Includes and Excludes' {
                $script:opt.Includes.Count | Should -Be 0
                $script:opt.Excludes.Count | Should -Be 0
            }
        }
        
    } 

    Describe 'New-AdfPublishOption' -Tag 'Unit' {

        Context 'When new object created' {
            It 'Should "TriggerStopMethod" = AllEnabled be default' {
                $script:result = New-AdfPublishOption
                $script:result.TriggerStopMethod | Should -Be 'AllEnabled'
            }
            It '"TriggerStopMethod" should be changeable' {
                $script:result.TriggerStopMethod = [TriggerStopTypes]::DeployableOnly
                $script:result.TriggerStopMethod | Should -Be 'DeployableOnly'
                $script:result.TriggerStopMethod = 'AllEnabled'
                $script:result.TriggerStopMethod | Should -Be 'AllEnabled'
            }
            It '"TriggerStopMethod" should not accept invalid values' {
                { $script:result.TriggerStopMethod = [TriggerStopTypes]::SomethingInvalid } | Should -Throw 
                { $script:result.TriggerStopMethod = 'SomethingInvalid' } | Should -Throw 
            }
        }

        Context 'When new object created' {
            It 'Should "TriggerStartMethod" = BasedOnSourceCode be default' {
                $script:result = New-AdfPublishOption
                $script:result.TriggerStartMethod | Should -Be 'BasedOnSourceCode'
            }
            It '"TriggerStartMethod" should be changeable' {
                $script:result.TriggerStartMethod = [TriggerStartTypes]::KeepPreviousState
                $script:result.TriggerStartMethod | Should -Be 'KeepPreviousState'
                $script:result.TriggerStartMethod = 'BasedOnSourceCode'
                $script:result.TriggerStartMethod | Should -Be 'BasedOnSourceCode'
            }
            It '"TriggerStartMethod" should not accept invalid values' {
                { $script:result.TriggerStartMethod = [TriggerStartTypes]::SomethingInvalid } | Should -Throw 
                { $script:result.TriggerStartMethod = 'SomethingInvalid' } | Should -Throw 
            }
        }

    }
}
