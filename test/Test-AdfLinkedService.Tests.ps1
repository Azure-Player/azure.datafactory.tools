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
    $azContext = Get-AzContext
    $script:params = @{
        DataFactoryName   = 'adf-example-uat'
        ResourceGroupName = 'rg-example-uat' 
        #SubscriptionID    = "{Your-subscriptionId-here}"
        SubscriptionID = $azContext.Subscription.Id
    }

    $script:success = @{
        succeeded = $true
    }

    $script:failure = @{
        succeeded = $false
    }

    Describe 'Test-AdfLinkedService' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Test-AdfLinkedService -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should fail when passing empty string as linked service name' {
            { Test-AdfLinkedService @params -TenantID 'x' -ClientID 'y' -ClientSecret 'z' -LinkedServiceName "" } | Should -Throw
        }

        Context 'When called with service principal auth' {
            BeforeAll {
                Mock Get-Bearer {return "xyz"}
                Mock Test-LinkedServiceConnection {return $script:success}
                Mock Test-LinkedServiceConnectionAzRestMethod {return $script:success}
            }
            It 'Should not fail when testing one linked service' {
                Test-AdfLinkedService @params -TenantID 'x' -ClientID 'y' -ClientSecret 'z' -LinkedServiceName "x"
                Should -Invoke -CommandName Get-Bearer -Times 1
                Should -Invoke -CommandName Test-LinkedServiceConnection -Times 1
                Should -Not -Invoke -CommandName Test-LinkedServiceConnectionAzRestMethod
            }
            It 'Should not fail when testing two linked service' {
                Test-AdfLinkedService @params -TenantID 'x' -ClientID 'y' -ClientSecret 'z' -LinkedServiceName "x,y"
                Should -Invoke -CommandName Get-Bearer -Times 1
                Should -Invoke -CommandName Test-LinkedServiceConnection -Times 2
                Should -Not -Invoke -CommandName Test-LinkedServiceConnectionAzRestMethod
            }
        }

        Context 'When called with Az Context auth' {
            BeforeAll {
                Mock Get-Bearer {return "xyz"}
                Mock Test-LinkedServiceConnection {return $script:success}
                Mock Test-LinkedServiceConnectionAzRestMethod {return $script:success}
            }
            It 'Should not fail when testing one linked service' {
                Test-AdfLinkedService @params -LinkedServiceName "x"
                Should -Invoke -CommandName Test-LinkedServiceConnectionAzRestMethod -Times 1
                Should -Not -Invoke -CommandName Test-LinkedServiceConnection
                Should -Not -Invoke -CommandName Get-Bearer
            }
            It 'Should not fail when testing two linked service' {
                Test-AdfLinkedService @params -LinkedServiceName "x,y"
                Should -Invoke -CommandName Test-LinkedServiceConnectionAzRestMethod -Times 2
                Should -Not -Invoke -CommandName Test-LinkedServiceConnection
                Should -Not -Invoke -CommandName Get-Bearer
            }
        }
        Context 'When linked services are timeouting' {
            BeforeAll {
                Mock Get-Bearer {return "xyz"}
                Mock Test-LinkedServiceConnection {return $script:failure}
                Mock Test-LinkedServiceConnectionAzRestMethod {return $script:failure}
            }
            It 'Should not fail when called with Service Principal' {
                Test-AdfLinkedService @params  -TenantID 'x' -ClientID 'y' -ClientSecret 'z' -LinkedServiceName "x"
            }
            It 'Should not fail when called with Az Context' {
                Test-AdfLinkedService @params -LinkedServiceName "x,y"
            }
        }
    }
}
