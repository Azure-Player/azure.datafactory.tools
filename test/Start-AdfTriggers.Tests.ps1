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
    $script:ResourceGroupName = 'rg-devops-factory'
    $script:DataFactoryName = 'TestFactory'

    Describe 'Start-AdfTriggers' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Start-AdfTriggers -ErrorAction Stop } | Should -Not -Throw
        }

        # Context 'When called without parameters' {
        #     It 'Should throw an error' {
        #         { Start-AdfTriggers } | Should -Throw
        #     }
        # }

        Context 'When called with null PublishOptions' {
            It 'Should create new PublishOptions' {
                # Arrange
                $adf = [Adf]::new()
                Mock New-AdfPublishOption { return [AdfPublishOption]::new() }
                Mock Start-Triggers { }

                # Act
                Start-AdfTriggers -adf $adf

                # Assert
                Should -Invoke New-AdfPublishOption -Times 1
                Should -Invoke Start-Triggers -Times 1
            }
        }

        Context 'When called with existing PublishOptions' {
            It 'Should not create new PublishOptions' {
                # Arrange
                $adf = [Adf]::new()
                $adf.PublishOptions = New-AdfPublishOption
                Mock New-AdfPublishOption { }
                Mock Start-Triggers { }

                # Act
                Start-AdfTriggers -adf $adf

                # Assert
                Should -Invoke New-AdfPublishOption -Times 0
                Should -Invoke Start-Triggers -Times 1
            }
        }

        Context 'When called with valid parameters' {
            BeforeAll {
                Mock Start-Triggers { }
            }

            It 'Should call Start-Triggers exactly once' {
                # Arrange
                $adf = [Adf]::new()
                $adf.PublishOptions = New-AdfPublishOption

                # Act
                Start-AdfTriggers -adf $adf

                # Assert
                Should -Invoke Start-Triggers -Times 1 -Exactly
            }

            It 'Should pass the adf object to Start-Triggers' {
                # Arrange
                $adf = [Adf]::new()
                $adf.PublishOptions = New-AdfPublishOption

                # Act
                Start-AdfTriggers -adf $adf

                # Assert
                Should -Invoke Start-Triggers -Times 1 -Exactly -ParameterFilter { $Adf -eq $adf }
            }
        }
    }
} 