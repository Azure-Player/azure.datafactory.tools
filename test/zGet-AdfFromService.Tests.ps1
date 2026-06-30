BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force

    # Shared factory stub
    $script:fakeAdfi = [PSCustomObject]@{
        DataFactoryId = '/subscriptions/sub-123/resourceGroups/rg-test/providers/Microsoft.DataFactory/factories/adf-test'
        Location      = 'northeurope'
    }

    # ---------------------------------------------------------------------------
    Describe 'Get-AdfFromService' -Tag 'Unit' {

        It 'Should exist' {
            { Get-Command -Name Get-AdfFromService -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'When all Az cmdlets succeed (happy path)' {
            BeforeEach {
                Mock Get-AzDataFactoryV2           { $script:fakeAdfi }
                Mock Get-AzDataFactoryV2Dataset           { @() }
                Mock Get-AzDataFactoryV2IntegrationRuntime { @() }
                Mock Get-AzDataFactoryV2LinkedService     { @() }
                Mock Get-AzDataFactoryV2Pipeline          { @() }
                Mock Get-AzDataFactoryV2DataFlow          { @() }
                Mock Get-AzDataFactoryV2Trigger           { @() }
                Mock Get-AzDFV2Credential                 { @() }
            }

            It 'Should return an AdfInstance with the correct factory name' {
                $result = Get-AdfFromService -FactoryName 'adf-test' -ResourceGroupName 'rg-test'
                $result.Name | Should -Be 'adf-test'
            }

            It 'Should not call Invoke-AzRestMethod when Az cmdlets succeed' {
                Mock Invoke-AzRestMethod { throw 'Should not be called' }
                { Get-AdfFromService -FactoryName 'adf-test' -ResourceGroupName 'rg-test' } | Should -Not -Throw
            }
        }

        Context 'When Get-AzDataFactoryV2Dataset throws a deserialization error (issue #480)' {
            BeforeEach {
                Mock Get-AzDataFactoryV2           { $script:fakeAdfi }
                Mock Get-AzDataFactoryV2Dataset           { throw 'Unable to deserialize the response.' }
                Mock Get-AzDataFactoryV2IntegrationRuntime { @() }
                Mock Get-AzDataFactoryV2LinkedService     { @() }
                Mock Get-AzDataFactoryV2Pipeline          { @() }
                Mock Get-AzDataFactoryV2DataFlow          { @() }
                Mock Get-AzDataFactoryV2Trigger           { @() }
                Mock Get-AzDFV2Credential                 { @() }
                Mock Invoke-AzRestMethod {
                    return [PSCustomObject]@{
                        StatusCode = 200
                        Content    = '{"value":[{"name":"ds_adls_csv","properties":{}},{"name":"ds_servicenow_v2","properties":{}}]}'
                    }
                }
            }

            It 'Should not throw' {
                { Get-AdfFromService -FactoryName 'adf-test' -ResourceGroupName 'rg-test' } | Should -Not -Throw
            }

            It 'Should fall back to REST API and return all datasets by name' {
                $result = Get-AdfFromService -FactoryName 'adf-test' -ResourceGroupName 'rg-test'
                $result.DataSets.Count | Should -Be 2
                $result.DataSets.Name | Should -Contain 'ds_adls_csv'
                $result.DataSets.Name | Should -Contain 'ds_servicenow_v2'
            }

            It 'Should return datasets as AdfPSDataset wrapper objects' {
                $result = Get-AdfFromService -FactoryName 'adf-test' -ResourceGroupName 'rg-test'
                $result.DataSets | ForEach-Object { $_.GetType().Name | Should -Be 'AdfPSDataset' }
            }

            It 'Should call Invoke-AzRestMethod with the correct datasets URL' {
                Get-AdfFromService -FactoryName 'adf-test' -ResourceGroupName 'rg-test'
                Assert-MockCalled Invoke-AzRestMethod -Times 1 -Exactly -ParameterFilter {
                    $Uri -like '*/datasets?api-version=2018-06-01'
                }
            }
        }

        Context 'When Get-AzDataFactoryV2LinkedService throws a deserialization error' {
            BeforeEach {
                Mock Get-AzDataFactoryV2           { $script:fakeAdfi }
                Mock Get-AzDataFactoryV2Dataset           { @() }
                Mock Get-AzDataFactoryV2IntegrationRuntime { @() }
                Mock Get-AzDataFactoryV2LinkedService     { throw 'Unable to deserialize the response.' }
                Mock Get-AzDataFactoryV2Pipeline          { @() }
                Mock Get-AzDataFactoryV2DataFlow          { @() }
                Mock Get-AzDataFactoryV2Trigger           { @() }
                Mock Get-AzDFV2Credential                 { @() }
                Mock Invoke-AzRestMethod {
                    return [PSCustomObject]@{
                        StatusCode = 200
                        Content    = '{"value":[{"name":"ls_adls","properties":{}},{"name":"ls_servicenow","properties":{}}]}'
                    }
                }
            }

            It 'Should not throw' {
                { Get-AdfFromService -FactoryName 'adf-test' -ResourceGroupName 'rg-test' } | Should -Not -Throw
            }

            It 'Should return linked services via REST fallback as AdfPSLinkedService objects' {
                $result = Get-AdfFromService -FactoryName 'adf-test' -ResourceGroupName 'rg-test'
                $result.LinkedServices.Count | Should -Be 2
                $result.LinkedServices | ForEach-Object { $_.GetType().Name | Should -Be 'AdfPSLinkedService' }
            }
        }

        Context 'When Get-AzDataFactoryV2Trigger throws a deserialization error' {
            BeforeEach {
                Mock Get-AzDataFactoryV2           { $script:fakeAdfi }
                Mock Get-AzDataFactoryV2Dataset           { @() }
                Mock Get-AzDataFactoryV2IntegrationRuntime { @() }
                Mock Get-AzDataFactoryV2LinkedService     { @() }
                Mock Get-AzDataFactoryV2Pipeline          { @() }
                Mock Get-AzDataFactoryV2DataFlow          { @() }
                Mock Get-AzDataFactoryV2Trigger           { throw 'Unable to deserialize the response.' }
                Mock Get-AzDFV2Credential                 { @() }
                Mock Invoke-AzRestMethod {
                    return [PSCustomObject]@{
                        StatusCode = 200
                        Content    = '{"value":[{"name":"tr_daily","properties":{"runtimeState":"Started"}},{"name":"tr_hourly","properties":{"runtimeState":"Stopped"}}]}'
                    }
                }
            }

            It 'Should not throw' {
                { Get-AdfFromService -FactoryName 'adf-test' -ResourceGroupName 'rg-test' } | Should -Not -Throw
            }

            It 'Should return triggers as AdfPSTrigger objects with correct RuntimeState' {
                $result = Get-AdfFromService -FactoryName 'adf-test' -ResourceGroupName 'rg-test'
                $result.Triggers.Count | Should -Be 2
                $result.Triggers | ForEach-Object { $_.GetType().Name | Should -Be 'AdfPSTrigger' }
                ($result.Triggers | Where-Object Name -eq 'tr_daily').RuntimeState  | Should -Be 'Started'
                ($result.Triggers | Where-Object Name -eq 'tr_hourly').RuntimeState | Should -Be 'Stopped'
            }
        }
    }

    # ---------------------------------------------------------------------------
    Describe 'Get-AdfObjectsFromServiceRestAPI' -Tag 'Unit' {

        It 'Should exist' {
            { Get-Command -Name Get-AdfObjectsFromServiceRestAPI -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'When the API returns an empty list' {
            BeforeEach {
                Mock Invoke-AzRestMethod {
                    return [PSCustomObject]@{ StatusCode = 200; Content = '{"value":[]}' }
                }
            }

            It 'Should return an empty collection' {
                $result = Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'datasets' -simpleType 'Dataset'
                @($result).Count | Should -Be 0
            }

            It 'Should call Invoke-AzRestMethod exactly once' {
                Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'datasets' -simpleType 'Dataset'
                Assert-MockCalled Invoke-AzRestMethod -Times 1 -Exactly
            }
        }

        Context 'When the API returns a single page of datasets' {
            BeforeEach {
                Mock Invoke-AzRestMethod {
                    return [PSCustomObject]@{
                        StatusCode = 200
                        Content    = '{"value":[{"name":"ds_one","properties":{}},{"name":"ds_two","properties":{}},{"name":"ds_three","properties":{}}]}'
                    }
                }
            }

            It 'Should return all items from the page' {
                $result = Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'datasets' -simpleType 'Dataset'
                $result.Count | Should -Be 3
            }

            It 'Should return AdfPSDataset wrapper objects' {
                $result = Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'datasets' -simpleType 'Dataset'
                $result | ForEach-Object { $_.GetType().Name | Should -Be 'AdfPSDataset' }
            }

            It 'Should preserve the dataset names' {
                $result = Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'datasets' -simpleType 'Dataset'
                $result.Name | Should -Contain 'ds_one'
                $result.Name | Should -Contain 'ds_two'
                $result.Name | Should -Contain 'ds_three'
            }

            It 'Should call Invoke-AzRestMethod exactly once (no extra pages)' {
                Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'datasets' -simpleType 'Dataset'
                Assert-MockCalled Invoke-AzRestMethod -Times 1 -Exactly
            }
        }

        Context 'When the API returns two pages (pagination)' {
            BeforeEach {
                $script:page2Url = 'https://management.azure.com/subscriptions/sub-123/.../datasets?api-version=2018-06-01&skipToken=page2'
                $script:callCount = 0
                Mock Invoke-AzRestMethod {
                    $script:callCount++
                    if ($script:callCount -eq 1) {
                        return [PSCustomObject]@{
                            StatusCode = 200
                            Content    = "{`"value`":[{`"name`":`"ds_p1_a`",`"properties`":{}},{`"name`":`"ds_p1_b`",`"properties`":{}}],`"nextLink`":`"$($script:page2Url)`"}"
                        }
                    } else {
                        return [PSCustomObject]@{
                            StatusCode = 200
                            Content    = '{"value":[{"name":"ds_p2_a","properties":{}}]}'
                        }
                    }
                }
            }

            It 'Should return items from all pages combined' {
                $result = Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'datasets' -simpleType 'Dataset'
                $result.Count | Should -Be 3
                $result.Name | Should -Contain 'ds_p1_a'
                $result.Name | Should -Contain 'ds_p1_b'
                $result.Name | Should -Contain 'ds_p2_a'
            }

            It 'Should call Invoke-AzRestMethod twice (once per page)' {
                Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'datasets' -simpleType 'Dataset'
                Assert-MockCalled Invoke-AzRestMethod -Times 2 -Exactly
            }

            It 'Should use the nextLink URL for the second request' {
                Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'datasets' -simpleType 'Dataset'
                Assert-MockCalled Invoke-AzRestMethod -Times 1 -Exactly -ParameterFilter {
                    $Uri -eq $script:page2Url
                }
            }
        }

        Context 'When called for each supported object type' {
            BeforeEach {
                Mock Invoke-AzRestMethod {
                    return [PSCustomObject]@{
                        StatusCode = 200
                        Content    = '{"value":[{"name":"obj1","properties":{"runtimeState":"Stopped"}}]}'
                    }
                }
            }

            It 'Should return AdfPSDataset for simpleType Dataset' {
                $r = Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'datasets' -simpleType 'Dataset'
                $r[0].GetType().Name | Should -Be 'AdfPSDataset'
            }

            It 'Should return AdfPSPipeline for simpleType Pipeline' {
                $r = Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'pipelines' -simpleType 'Pipeline'
                $r[0].GetType().Name | Should -Be 'AdfPSPipeline'
            }

            It 'Should return AdfPSLinkedService for simpleType LinkedService' {
                $r = Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'linkedservices' -simpleType 'LinkedService'
                $r[0].GetType().Name | Should -Be 'AdfPSLinkedService'
            }

            It 'Should return AdfPSIntegrationRuntime for simpleType IntegrationRuntime' {
                $r = Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'integrationruntimes' -simpleType 'IntegrationRuntime'
                $r[0].GetType().Name | Should -Be 'AdfPSIntegrationRuntime'
            }

            It 'Should return AdfPSDataFlow for simpleType DataFlow' {
                $r = Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'dataflows' -simpleType 'DataFlow'
                $r[0].GetType().Name | Should -Be 'AdfPSDataFlow'
            }

            It 'Should return AdfPSTrigger for simpleType Trigger with RuntimeState' {
                $r = Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'triggers' -simpleType 'Trigger'
                $r[0].GetType().Name | Should -Be 'AdfPSTrigger'
                $r[0].RuntimeState | Should -Be 'Stopped'
            }
        }

        Context 'When the API returns a non-200 status code' {
            BeforeEach {
                Mock Invoke-AzRestMethod {
                    return [PSCustomObject]@{ StatusCode = 403; Content = '{"error":{"code":"AuthorizationFailed"}}' }
                }
            }

            It 'Should throw when ErrorAction Stop is used' {
                { Get-AdfObjectsFromServiceRestAPI -adfi $script:fakeAdfi -typePlural 'datasets' -simpleType 'Dataset' -ErrorAction Stop } | Should -Throw
            }
        }
    }

    # ---------------------------------------------------------------------------
    Describe 'Get-AdfFromService' -Tag 'Integration' {
        # Variables for use in integration tests
        $t = Get-TargetEnv 'adf2'
        $script:adfName = $t.DataFactoryName
        $script:rg      = $t.ResourceGroupName

        It 'Should execute' {
            Get-AdfFromService -FactoryName $adfName -ResourceGroupName $rg
        }
    }

}

