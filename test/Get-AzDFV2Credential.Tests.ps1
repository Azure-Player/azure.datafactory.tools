BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force

    Describe 'Get-AzDFV2Credential' -Tag 'Unit' {

        It 'Should exist' {
            { Get-Command -Name Get-AzDFV2Credential -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'When the API returns no credentials' {
            BeforeEach {
                $script:adfi = [PSCustomObject]@{ DataFactoryId = '/subscriptions/sub-123/resourceGroups/rg/providers/Microsoft.DataFactory/factories/adf1' }

                Mock Get-AzAccessToken {
                    return [PSCustomObject]@{ Token = 'fake-token-abc' }
                }
                Mock Invoke-AzRestMethod {
                    return [PSCustomObject]@{ StatusCode = 200; Content = '{"value":[]}' }
                }
            }

            It 'Should return an empty list' {
                $result = Get-AzDFV2Credential -adfi $script:adfi
                @($result).Count | Should -Be 0
            }

            It 'Should call Get-AzAccessToken once' {
                Get-AzDFV2Credential -adfi $script:adfi
                Assert-MockCalled Get-AzAccessToken -Times 1 -Exactly
            }

            It 'Should call Invoke-AzRestMethod once' {
                Get-AzDFV2Credential -adfi $script:adfi
                Assert-MockCalled Invoke-AzRestMethod -Times 1 -Exactly
            }

            It 'Should call Invoke-AzRestMethod with correct credentials URL' {
                Get-AzDFV2Credential -adfi $script:adfi
                Assert-MockCalled Invoke-AzRestMethod -Times 1 -Exactly -ParameterFilter {
                    $Uri -eq "https://management.azure.com$($script:adfi.DataFactoryId)/credentials?api-version=2018-06-01"
                }
            }

            It 'Should call Invoke-AzRestMethod using GET method' {
                Get-AzDFV2Credential -adfi $script:adfi
                Assert-MockCalled Invoke-AzRestMethod -Times 1 -Exactly -ParameterFilter {
                    $Method -eq 'GET'
                }
            }
        }

        Context 'When the API returns multiple credentials' {
            BeforeEach {
                $script:adfi = [PSCustomObject]@{ DataFactoryId = '/subscriptions/sub-123/resourceGroups/rg/providers/Microsoft.DataFactory/factories/adf1' }

                $cred1 = [PSCustomObject]@{ name = 'cred1'; type = 'Microsoft.DataFactory/factories/credentials'; properties = @{} }
                $cred2 = [PSCustomObject]@{ name = 'cred2'; type = 'Microsoft.DataFactory/factories/credentials'; properties = @{} }
                $script:credJson = @{ value = @($cred1, $cred2) } | ConvertTo-Json -Depth 5

                Mock Get-AzAccessToken {
                    return [PSCustomObject]@{ Token = 'fake-token-abc' }
                }
                Mock Invoke-AzRestMethod {
                    return [PSCustomObject]@{ StatusCode = 200; Content = $script:credJson }
                }
            }

            It 'Should return all credentials as AdfPSCredential objects' {
                $result = Get-AzDFV2Credential -adfi $script:adfi
                $result.Count | Should -Be 2
                $result | ForEach-Object { $_.GetType().Name | Should -Be 'AdfPSCredential' }
            }

            It 'Should populate the Name property from the API response' {
                $result = Get-AzDFV2Credential -adfi $script:adfi
                $result[0].Name | Should -Be 'cred1'
                $result[1].Name | Should -Be 'cred2'
            }

            It 'Should populate the Child property with the raw API object' {
                $result = Get-AzDFV2Credential -adfi $script:adfi
                $result[0].Child.name | Should -Be 'cred1'
                $result[1].Child.name | Should -Be 'cred2'
            }
        }

        Context 'When Invoke-AzRestMethod throws' {
            BeforeEach {
                $script:adfi = [PSCustomObject]@{ DataFactoryId = '/subscriptions/sub-123/resourceGroups/rg/providers/Microsoft.DataFactory/factories/adf1' }

                Mock Get-AzAccessToken {
                    return [PSCustomObject]@{ Token = 'fake-token-abc' }
                }
                Mock Invoke-AzRestMethod { throw 'Unauthorized' }
            }

            It 'Should propagate the error' {
                { Get-AzDFV2Credential -adfi $script:adfi } | Should -Throw
            }
        }
    }
}
