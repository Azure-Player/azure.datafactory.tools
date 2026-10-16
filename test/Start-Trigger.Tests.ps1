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

    Describe 'Command ' -Tag 'Unit' {
        It 'Start-Triggers Should exist' {
            { Get-Command -Name Start-Triggers -ErrorAction Stop } | Should -Not -Throw
        }
        It 'Start-Trigger Should exist' {
            { Get-Command -Name Start-Trigger -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Describe 'Start-Trigger' -Tag 'Unit' {

        It 'Should retry after the first failure' {
            $script:attempts = 2
            Mock Start-AzDataFactoryV2Trigger { $attempts--; if ($attempts -eq 0) { Write-Host 'OK' } else { throw 'BadRequest' } }
            Start-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1'
            Should -Invoke Start-AzDataFactoryV2Trigger -Times 2
        }

        It 'Should retry max 5 times when failure' {
            Mock Start-AzDataFactoryV2Trigger { throw 'BadRequest' }
            Start-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1'
            Should -Invoke Start-AzDataFactoryV2Trigger -Times 5
        }

        It 'Should wait for provisioning and retry when trigger cannot be updated during provisioning' {
            $script:startAttempt = 0
            Mock Start-AzDataFactoryV2Trigger {
                $script:startAttempt++
                if ($script:startAttempt -eq 1) { throw 'BadRequest: Resource cannot be updated during provisioning' }
            }
            $script:getAttempt = 0
            Mock Get-AzDataFactoryV2Trigger {
                $script:getAttempt++
                $state = if ($script:getAttempt -eq 1) { 'Provisioning' } else { 'Succeeded' }
                return [PSCustomObject]@{ Properties = [PSCustomObject]@{ ProvisioningState = $state } }
            }
            Mock Start-Sleep {}

            Start-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1'

            Should -Invoke Start-AzDataFactoryV2Trigger -Times 2
            Should -Invoke Get-AzDataFactoryV2Trigger -Times 2
        }

    }

    # Az cmdlets report failures as non-terminating errors (they do not throw) #508
    Describe 'Start-Trigger when Az cmdlet writes a non-terminating error #508' -Tag 'Unit' {

        BeforeEach {
            $ErrorActionPreference = 'Continue'     # default preference, as in most pipelines
            Mock Start-Sleep {}
            Mock Write-Warning {}
        }

        It 'Should return true when started' {
            Mock Start-AzDataFactoryV2Trigger { }
            Start-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1' | Should -BeTrue
            Should -Invoke Start-AzDataFactoryV2Trigger -Times 1 -Exactly
        }

        It 'Should retry a transient error, then warn and return false' {
            Mock Start-AzDataFactoryV2Trigger { Write-Error 'Conflict: There are concurrent operations on the trigger' }
            Start-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1' | Should -BeFalse
            Should -Invoke Start-AzDataFactoryV2Trigger -Times 5 -Exactly
            Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like '*concurrent operations*' }
        }

        It 'Should succeed when a retry works' {
            $script:startAttempt = 0
            Mock Start-AzDataFactoryV2Trigger { $script:startAttempt++; if ($script:startAttempt -eq 1) { Write-Error 'Conflict: concurrent operations' } }
            Start-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1' | Should -BeTrue
            Should -Invoke Start-AzDataFactoryV2Trigger -Times 2 -Exactly
            Should -Invoke Write-Warning -Times 0 -Exactly
        }

        It 'Should not retry a permanent error (missing pipeline references)' {
            Mock Start-AzDataFactoryV2Trigger { Write-Error 'HTTP Status Code: BadRequest Error Code: BadRequest Error Message: Missing or invalid pipeline references for trigger tr1' }
            Start-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1' | Should -BeFalse
            Should -Invoke Start-AzDataFactoryV2Trigger -Times 1 -Exactly
            Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like '*Missing or invalid pipeline references*' }
        }

        It 'Should not write the error to the error stream' {
            Mock Start-AzDataFactoryV2Trigger { Write-Error 'Missing or invalid pipeline references for trigger tr1' }
            $out = Start-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1' 2>&1
            @($out | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }) | Should -BeNullOrEmpty
        }
    }

    Describe 'Start-Triggers when a trigger fails to start #508' -Tag 'Unit' {

        BeforeAll {
            Mock Start-Trigger { param ($ResourceGroupName, $DataFactoryName, $Name) return ($Name -ne 'tr2') }
            Mock Write-Warning {}

            $script:adf = [Adf]::new()
            $script:adf.Name = 'adf'
            $script:adf.ResourceGroupName = 'rg'
            $script:adf.PublishOptions = New-AdfPublishOption
            foreach ($n in 'tr1', 'tr2', 'tr3') {
                $script:adf.Triggers.Add([PSCustomObject]@{ Name = $n; Body = [PSCustomObject]@{ properties = [PSCustomObject]@{ runtimeState = 'Started' } } }) | Out-Null
            }
        }

        It 'Should carry on (not throw) and try to start all triggers' {
            { Start-Triggers -adf $script:adf } | Should -Not -Throw
            Should -Invoke Start-Trigger -Times 3 -Exactly
        }
        It 'Should warn about triggers which failed to start' {
            Should -Invoke Write-Warning -Times 1 -Exactly -Scope Describe -ParameterFilter { $Message -like '*tr2*' -and $Message -notlike '*tr1*' -and $Message -notlike '*tr3*' }
        }
    }
}




# https://pester.dev/docs/usage/mocking

