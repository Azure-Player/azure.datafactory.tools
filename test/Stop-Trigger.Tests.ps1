BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force

    Describe 'Command ' -Tag 'Unit' {
        It 'Stop-Trigger Should exist' {
            { Get-Command -Name Stop-Trigger -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Describe 'Stop-Trigger' -Tag 'Unit' {

        BeforeEach {
            Mock Start-Sleep {}
        }

        It 'Should return true when stopped at first attempt' {
            Mock Stop-AzDataFactoryV2Trigger { }
            $r = Stop-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1'
            $r | Should -BeTrue
            Should -Invoke Stop-AzDataFactoryV2Trigger -Times 1 -Exactly
        }

        It 'Should retry after the first failure' {
            $script:stopAttempt = 0
            Mock Stop-AzDataFactoryV2Trigger { $script:stopAttempt++; if ($script:stopAttempt -eq 1) { throw 'Conflict: concurrent operations' } }
            $r = Stop-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1'
            $r | Should -BeTrue
            Should -Invoke Stop-AzDataFactoryV2Trigger -Times 2 -Exactly
        }

        It 'Should retry max 5 times when failure, warn and return false' {
            Mock Stop-AzDataFactoryV2Trigger { throw 'BadRequest' }
            Mock Write-Warning {}
            $r = Stop-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1'
            $r | Should -BeFalse
            Should -Invoke Stop-AzDataFactoryV2Trigger -Times 5 -Exactly
            Should -Invoke Write-Warning -Times 1 -Exactly
        }

        It 'Should wait for provisioning and retry when trigger cannot be updated during provisioning' {
            $script:stopAttempt = 0
            Mock Stop-AzDataFactoryV2Trigger {
                $script:stopAttempt++
                if ($script:stopAttempt -eq 1) { throw 'BadRequest: Resource cannot be updated during provisioning' }
            }
            $script:getAttempt = 0
            Mock Get-AzDataFactoryV2Trigger {
                $script:getAttempt++
                $state = if ($script:getAttempt -eq 1) { 'Provisioning' } else { 'Succeeded' }
                return [PSCustomObject]@{ Properties = [PSCustomObject]@{ ProvisioningState = $state } }
            }

            $r = Stop-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1'

            $r | Should -BeTrue
            Should -Invoke Stop-AzDataFactoryV2Trigger -Times 2 -Exactly
            Should -Invoke Get-AzDataFactoryV2Trigger -Times 2 -Exactly
        }
    }

    # Az cmdlets report failures as non-terminating errors (they do not throw) #508
    Describe 'Stop-Trigger when Az cmdlet writes a non-terminating error #508' -Tag 'Unit' {

        BeforeEach {
            $ErrorActionPreference = 'Continue'     # default preference, as in most pipelines
            Mock Start-Sleep {}
            Mock Write-Warning {}
        }

        It 'Should retry a transient error, then warn and return false' {
            Mock Stop-AzDataFactoryV2Trigger { Write-Error 'Conflict: There are concurrent operations on the trigger' }
            Stop-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1' | Should -BeFalse
            Should -Invoke Stop-AzDataFactoryV2Trigger -Times 5 -Exactly
            Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like '*concurrent operations*' }
        }

        It 'Should succeed when a retry works' {
            $script:stopAttempt = 0
            Mock Stop-AzDataFactoryV2Trigger { $script:stopAttempt++; if ($script:stopAttempt -eq 1) { Write-Error 'Conflict: concurrent operations' } }
            Stop-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1' | Should -BeTrue
            Should -Invoke Stop-AzDataFactoryV2Trigger -Times 2 -Exactly
        }

        It 'Should not write the error to the error stream' {
            Mock Stop-AzDataFactoryV2Trigger { Write-Error 'Conflict: concurrent operations' }
            $out = Stop-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1' 2>&1
            @($out | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }) | Should -BeNullOrEmpty
        }
    }

    Describe 'Stop-Triggers when a trigger fails to stop' -Tag 'Unit' {

        BeforeAll {
            Mock Get-SortedTriggers {
                @(
                    [PSCustomObject]@{ Name = 'tr1'; RuntimeState = 'Started' }
                    [PSCustomObject]@{ Name = 'tr2'; RuntimeState = 'Started' }
                )
            }
            Mock Stop-Trigger { param ($ResourceGroupName, $DataFactoryName, $Name) return ($Name -ne 'tr2') }
            Mock Write-Warning {}

            $script:adf = [Adf]::new()
            $script:adf.Name = 'adf'
            $script:adf.ResourceGroupName = 'rg'
            $script:adf.PublishOptions = New-AdfPublishOption
            Stop-Triggers -adf $script:adf
        }

        It 'Should try to stop all active triggers' {
            Should -Invoke Stop-Trigger -Times 2 -Exactly -Scope Describe
        }
        It 'Should register only successfully stopped triggers' {
            $script:adf.StoppedTriggerNames | Should -Be @('tr1')
        }
        It 'Should keep the RuntimeState of trigger which failed to stop' {
            ($script:adf.TargetTriggerNames | Where-Object Name -eq 'tr1').RuntimeState | Should -Be 'Stopped'
            ($script:adf.TargetTriggerNames | Where-Object Name -eq 'tr2').RuntimeState | Should -Be 'Started'
        }
        It 'Should warn about triggers which failed to stop' {
            Should -Invoke Write-Warning -Times 1 -Exactly -Scope Describe -ParameterFilter { $Message -like '*tr2*' }
        }
    }
}
