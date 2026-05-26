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
            Assert-MockCalled Start-AzDataFactoryV2Trigger -Times 2
        }

        It 'Should retry max 5 times when failure' {
            Mock Start-AzDataFactoryV2Trigger { throw 'BadRequest' }
            Start-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1'
            Assert-MockCalled Start-AzDataFactoryV2Trigger -Times 5
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

            Assert-MockCalled Start-AzDataFactoryV2Trigger -Times 2
            Assert-MockCalled Get-AzDataFactoryV2Trigger -Times 2
        }

    }
}




# https://pester.dev/docs/usage/mocking

