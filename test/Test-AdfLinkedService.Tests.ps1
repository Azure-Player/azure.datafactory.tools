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

    Describe 'Test-AdfLinkedService #382' -Tag 'Unit' {
        BeforeAll {
            $script:p = @{ DataFactoryName = 'adf'; ResourceGroupName = 'rg'; SubscriptionID = 's' }
        }

        BeforeEach {
            $ErrorActionPreference = 'Continue'
            Mock Write-Host {}
            Mock Get-Bearer { return 'xyz' }
            Mock Test-LinkedServiceConnectionAzRestMethod {
                if ($LinkedServiceName -eq 'LS1' -or $LinkedServiceName -eq 'LS2') { return [PSCustomObject]@{ succeeded = $true } }
                return '{"error":{"code":"NotFound","message":"Linked service not found"}}' | ConvertFrom-Json
            }
        }

        It 'Should count an error response (no "succeeded" property) as failed, not throw' {
            $r = Test-AdfLinkedService @p -LinkedServiceName 'LS1,Missing'
            $r.Passed | Should -Be 1
            $r.Failed | Should -Be 1
            $r.Report['002) Missing'] | Should -BeFalse
            $r.Errors['002) Missing'] | Should -Be 'NotFound: Linked service not found'
        }

        It 'Should take the error message from "errors" of a failed connection test' {
            Mock Test-LinkedServiceConnectionAzRestMethod {
                return '{"succeeded":false,"errors":[{"code":22300,"message":"Cannot connect to SQL Database."}]}' | ConvertFrom-Json
            }
            $r = Test-AdfLinkedService @p -LinkedServiceName 'LS1'
            $r.Failed | Should -Be 1
            $r.Errors['001) LS1'] | Should -Be '22300: Cannot connect to SQL Database.'
        }

        It 'Should trim names of a comma-separated list' {
            $r = Test-AdfLinkedService @p -LinkedServiceName 'LS1, LS2'
            $r.Passed | Should -Be 2
            Should -Invoke Test-LinkedServiceConnectionAzRestMethod -Times 1 -Exactly -ParameterFilter { $LinkedServiceName -eq 'LS2' }
        }

        It 'Should accept an array of names' {
            $r = Test-AdfLinkedService @p -LinkedServiceName 'LS1', 'LS2'
            $r.Total | Should -Be 2
            $r.Passed | Should -Be 2
        }

        It 'Should skip empty items' {
            $r = Test-AdfLinkedService @p -LinkedServiceName 'LS1,, ,'
            $r.Total | Should -Be 1
            Should -Invoke Test-LinkedServiceConnectionAzRestMethod -Times 1 -Exactly
        }

        It 'Should accept one comma-separated [string] as the Azure DevOps extension task passes it' {
            [string] $LinkedServiceName = 'LS1,LS2'
            $r = Test-AdfLinkedService -LinkedServiceName $LinkedServiceName -DataFactoryName 'adf' -ResourceGroupName 'rg' -SubscriptionID 's'
            $r.Total | Should -Be 2
            $r.Passed | Should -Be 2
        }

        It 'Should read names and parameters from a json definition file' {
            $file = Join-Path $TestDrive 'ls.json'
            '{"linkedServices":[{"name":"LS1","parameters":{"p1":"v1"}},{"name":"LS2"}]}' | Set-Content -Path $file -Encoding utf8
            $r = Test-AdfLinkedService @p -LinkedServiceName $file
            $r.Total | Should -Be 2
            Should -Invoke Test-LinkedServiceConnectionAzRestMethod -Times 1 -Exactly -ParameterFilter { $LinkedServiceName -eq 'LS1' -and $Params.p1 -eq 'v1' }
        }

        It 'Should count a failed call with Service Principal as failed, also when ErrorActionPreference is Stop' {
            $ErrorActionPreference = 'Stop'
            Mock Get-LinkedServiceBody { return '{"linkedService":{"name":"LS1","properties":{}}}' }
            Mock Invoke-RestMethod { throw 'Response status code does not indicate success: 403 (Forbidden).' }
            $r = Test-AdfLinkedService @p -TenantID 'x' -ClientID 'y' -ClientSecret 'z' -LinkedServiceName 'LS1'
            $r.Failed | Should -Be 1
            $r.Errors['001) LS1'] | Should -BeLike '*403*'
        }

        It 'Should count a missing linked service with Service Principal as failed and test the next one' {
            $ErrorActionPreference = 'Stop'
            Mock Invoke-RestMethod {
                if ($Method -eq 'GET' -and $Uri -like '*/linkedservices/Missing?*') { throw 'Response status code does not indicate success: 404 (Not Found).' }
                if ($Method -eq 'GET') { return [PSCustomObject]@{ name = 'LS1'; properties = [PSCustomObject]@{} } }
                return [PSCustomObject]@{ succeeded = $true }
            }
            $r = Test-AdfLinkedService @p -TenantID 'x' -ClientID 'y' -ClientSecret 'z' -LinkedServiceName 'Missing,LS1'
            $r.Failed | Should -Be 1
            $r.Passed | Should -Be 1
            $r.Errors['001) Missing'] | Should -BeLike '*404*'
        }
    }

    Describe 'Test-LinkedServiceConnectionAzRestMethod #382' -Tag 'Unit' {
        BeforeEach {
            $ErrorActionPreference = 'Continue'
            Mock Get-LinkedServiceBodyAzRestMethod { return '{"linkedService":{"name":"LS1","properties":{}}}' }
        }

        It 'Should return the error response when the API returns an HTTP error' {
            Mock Invoke-AzRestMethod { [PSCustomObject]@{ StatusCode = 404; Content = '{"error":{"code":"NotFound","message":"Not found"}}' } }
            $r = Test-LinkedServiceConnectionAzRestMethod -LinkedServiceName 'LS1' -DataFactoryName 'adf' -ResourceGroupName 'rg' -SubscriptionID 's'
            $r.error.code | Should -Be 'NotFound'
        }

        It 'Should return a failure instead of an error when Invoke-AzRestMethod throws, also when ErrorActionPreference is Stop' {
            $ErrorActionPreference = 'Stop'
            Mock Invoke-AzRestMethod { throw 'No connection' }
            $r = Test-LinkedServiceConnectionAzRestMethod -LinkedServiceName 'LS1' -DataFactoryName 'adf' -ResourceGroupName 'rg' -SubscriptionID 's'
            $r.succeeded | Should -BeFalse
            $r.error.message | Should -BeLike '*No connection*'
        }

        It 'Should return the API error without testing when the linked service cannot be read' {
            Mock Get-LinkedServiceBodyAzRestMethod { return '{"linkedService":{"error":{"code":"NotFound","message":"Not found"}}}' }
            Mock Invoke-AzRestMethod {}
            $r = Test-LinkedServiceConnectionAzRestMethod -LinkedServiceName 'Missing' -DataFactoryName 'adf' -ResourceGroupName 'rg' -SubscriptionID 's'
            $r.error.code | Should -Be 'NotFound'
            Should -Invoke Invoke-AzRestMethod -Times 0 -Exactly
        }

        It 'Should add parameters to a linked service which has none' {
            Mock Invoke-AzRestMethod { [PSCustomObject]@{ StatusCode = 200; Content = '{"succeeded":true}' } }
            $r = Test-LinkedServiceConnectionAzRestMethod -LinkedServiceName 'LS1' -DataFactoryName 'adf' -ResourceGroupName 'rg' -SubscriptionID 's' -Params ([PSCustomObject]@{ p1 = 'v1' })
            $r.succeeded | Should -BeTrue
            Should -Invoke Invoke-AzRestMethod -Times 1 -Exactly -ParameterFilter { ($Payload | ConvertFrom-Json).linkedService.properties.parameters.p1 -eq 'v1' }
        }
    }
}
