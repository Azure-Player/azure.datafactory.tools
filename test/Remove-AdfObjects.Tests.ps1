BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {

    Describe 'Remove-AdfObject' -Tag 'Unit' {

        BeforeEach {
            $ErrorActionPreference = 'Continue'
            Mock Write-Host {}
            $script:ins = [AdfInstance]::new()
            $script:ins.Name = 'adf'
            $script:ins.ResourceGroupName = 'rg'
        }

        It 'Should take the factory from adfInstance and work without a source model' {
            Mock Remove-AzDataFactoryV2Pipeline {}
            $p = [AdfPSPipeline]::new('PL_A')
            $script:ins.Pipelines.Add($p) | Out-Null
            Remove-AdfObject -obj $p -adfInstance $script:ins
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 1 -Exactly -ParameterFilter {
                $ResourceGroupName -eq 'rg' -and $DataFactoryName -eq 'adf' -and $Name -eq 'PL_A'
            }
        }

        It 'Should throw for an unsupported type' {
            $o = [PSCustomObject]@{ Name = 'x' }
            { Remove-AdfObject -obj $o -adfInstance $script:ins } | Should -Throw '*ADFT0018*'
        }

        It 'Should throw when the Az cmdlet writes a non-terminating error' {
            Mock Remove-AzDataFactoryV2Dataset { Write-Error 'BadRequest: something went wrong' }
            $d = [AdfPSDataset]::new('DS_A')
            { Remove-AdfObject -obj $d -adfInstance $script:ins } | Should -Throw '*BadRequest*'
        }

        It 'Should delete the referencing object first when it is in the selection' {
            $script:dsDeleteAttempt = 0
            Mock Remove-AzDataFactoryV2Dataset {
                $script:dsDeleteAttempt++
                if ($script:dsDeleteAttempt -eq 1) { Write-Error 'The document cannot be deleted since it is referenced by PL_A.' }
            }
            Mock Remove-AzDataFactoryV2Pipeline {}
            $d = [AdfPSDataset]::new('DS_A')
            $p = [AdfPSPipeline]::new('PL_A')
            $script:ins.DataSets.Add($d) | Out-Null
            $script:ins.Pipelines.Add($p) | Out-Null
            $deleted = [System.Collections.ArrayList]::new()
            Remove-AdfObject -obj $d -adfInstance $script:ins -Selection @($d, $p) -Deleted $deleted
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 1 -Exactly
            Should -Invoke Remove-AzDataFactoryV2Dataset -Times 2 -Exactly
            $deleted.Count | Should -Be 2
        }

        It 'Should throw and not delete the referencing object when it is not in the selection' {
            Mock Remove-AzDataFactoryV2Dataset { Write-Error 'The document cannot be deleted since it is referenced by PL_A.' }
            Mock Remove-AzDataFactoryV2Pipeline {}
            $d = [AdfPSDataset]::new('DS_A')
            $p = [AdfPSPipeline]::new('PL_A')
            $script:ins.DataSets.Add($d) | Out-Null
            $script:ins.Pipelines.Add($p) | Out-Null
            { Remove-AdfObject -obj $d -adfInstance $script:ins -Selection @($d) } | Should -Throw '*ADFT0034*PL_A*'
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 0 -Exactly
        }

        It 'Should skip an object that has already been deleted' {
            Mock Remove-AzDataFactoryV2Pipeline {}
            $p = [AdfPSPipeline]::new('PL_A')
            $deleted = [System.Collections.ArrayList]::new()
            $deleted.Add($p) | Out-Null
            Remove-AdfObject -obj $p -adfInstance $script:ins -Selection @($p) -Deleted $deleted
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 0 -Exactly
        }
    }

    Describe 'Remove-AdfObjects' -Tag 'Unit' {

        BeforeEach {
            $ErrorActionPreference = 'Continue'
            Mock Write-Host {}
            $script:ins = [AdfInstance]::new()
            $script:ins.Id = '/subscriptions/s/resourceGroups/rg/providers/Microsoft.DataFactory/factories/adf'
            $script:ins.Name = 'adf'
            $script:ins.ResourceGroupName = 'rg'
            $script:ins.Pipelines.Add([AdfPSPipeline]::new('PL_Old1')) | Out-Null
            $script:ins.Pipelines.Add([AdfPSPipeline]::new('PL_Old2')) | Out-Null
            $script:ins.Pipelines.Add([AdfPSPipeline]::new('PL_Keep')) | Out-Null
            $script:ins.DataSets.Add([AdfPSDataset]::new('DS_Old')) | Out-Null
            $script:ins.Triggers.Add([AdfPSTrigger]::new('TR_Old', 'Started')) | Out-Null
            Mock Get-AdfFromService { $script:ins }
            Mock Get-AdfObjectFolder {
                @{ 'pipeline.PL_Old1' = 'Archive'; 'pipeline.PL_Old2' = 'Archive/2020'; 'pipeline.PL_Keep' = 'Main'; 'dataset.DS_Old' = '' }
            }
            Mock Remove-AzDataFactoryV2Pipeline {}
            Mock Remove-AzDataFactoryV2Dataset {}
            Mock Remove-AzDataFactoryV2Trigger {}
            Mock Stop-AzDataFactoryV2Trigger {}
        }

        It 'Should be exported' {
            Get-Command -Module azure.datafactory.tools -Name 'Remove-AdfObjects' | Should -Not -BeNullOrEmpty
        }

        It 'Should delete only objects matching the patterns' {
            $r = Remove-AdfObjects -ResourceGroupName 'rg' -DataFactoryName 'adf' -Pattern 'pipeline.PL_Old*', 'dataset.*'
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 2 -Exactly
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 0 -Exactly -ParameterFilter { $Name -eq 'PL_Keep' }
            Should -Invoke Remove-AzDataFactoryV2Dataset -Times 1 -Exactly
            Should -Invoke Remove-AzDataFactoryV2Trigger -Times 0 -Exactly
            Should -Invoke Get-AdfObjectFolder -Times 0 -Exactly
            $r.Count | Should -Be 3
        }

        It 'Should filter by folder when a pattern has @folder' {
            Remove-AdfObjects -ResourceGroupName 'rg' -DataFactoryName 'adf' -Pattern 'pipeline.*@Archive'
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 1 -Exactly -ParameterFilter { $Name -eq 'PL_Old1' }
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 1 -Exactly
        }

        It 'Should include subfolders with a wildcard folder pattern' {
            Remove-AdfObjects -ResourceGroupName 'rg' -DataFactoryName 'adf' -Pattern 'pipeline.*@Archive*'
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 2 -Exactly
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 0 -Exactly -ParameterFilter { $Name -eq 'PL_Keep' }
        }

        It 'Should delete triggers before pipelines and stop started triggers' {
            $script:order = [System.Collections.ArrayList]::new()
            Mock Remove-AzDataFactoryV2Pipeline { $script:order.Add("pipeline.$Name") | Out-Null }
            Mock Remove-AzDataFactoryV2Trigger { $script:order.Add("trigger.$Name") | Out-Null }
            Remove-AdfObjects -ResourceGroupName 'rg' -DataFactoryName 'adf' -Pattern 'pipeline.PL_Old1', 'trigger.*'
            $script:order[0] | Should -Be 'trigger.TR_Old'
            $script:order[1] | Should -Be 'pipeline.PL_Old1'
            Should -Invoke Stop-AzDataFactoryV2Trigger -Times 1 -Exactly
        }

        It 'Should not delete anything with -WhatIf' {
            $r = Remove-AdfObjects -ResourceGroupName 'rg' -DataFactoryName 'adf' -Pattern '*.*' -WhatIf
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 0 -Exactly
            Should -Invoke Remove-AzDataFactoryV2Dataset -Times 0 -Exactly
            Should -Invoke Remove-AzDataFactoryV2Trigger -Times 0 -Exactly
            $r | Should -BeNullOrEmpty
        }

        It 'Should delete what a deployment with the given option would deploy' {
            $opt = New-AdfPublishOption
            $opt.Includes.Add('pipeline.PL_Old*', '')
            $opt.Excludes.Add('pipeline.PL_Old2', '')
            Remove-AdfObjects -ResourceGroupName 'rg' -DataFactoryName 'adf' -Option $opt
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 1 -Exactly -ParameterFilter { $Name -eq 'PL_Old1' }
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 1 -Exactly
            Should -Invoke Remove-AzDataFactoryV2Dataset -Times 0 -Exactly
        }

        It 'Should stop at the first failed delete' {
            Mock Remove-AzDataFactoryV2Trigger { Write-Error 'BadRequest: cannot delete' }
            { Remove-AdfObjects -ResourceGroupName 'rg' -DataFactoryName 'adf' -Pattern 'pipeline.PL_Old1', 'trigger.*' } | Should -Throw '*BadRequest*'
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 0 -Exactly
        }

        It 'Should do nothing when no object matches' {
            $r = Remove-AdfObjects -ResourceGroupName 'rg' -DataFactoryName 'adf' -Pattern 'pipeline.Nothing*'
            Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 0 -Exactly
            $r | Should -BeNullOrEmpty
        }
    }

    Describe 'Get-AdfObjectFolder' -Tag 'Unit' {

        BeforeEach {
            $ErrorActionPreference = 'Continue'
            $script:ins = [AdfInstance]::new()
            $script:ins.Id = '/subscriptions/s/resourceGroups/rg/providers/Microsoft.DataFactory/factories/adf'
        }

        It 'Should map type.name to folder for pipelines, datasets and data flows' {
            Mock Invoke-AzRestMethod {
                $body = switch -Wildcard ($Uri) {
                    '*/pipelines?*' { '{"value":[{"name":"PL_A","properties":{"folder":{"name":"Archive/2020"}}},{"name":"PL_B","properties":{}}]}' }
                    '*/datasets?*'  { '{"value":[{"name":"DS_A","properties":{"folder":{"name":"Sales"}}}]}' }
                    '*/dataflows?*' { '{"value":[]}' }
                }
                [PSCustomObject]@{ StatusCode = 200; Content = $body }
            }
            $r = Get-AdfObjectFolder -adfInstance $script:ins
            $r['pipeline.PL_A'] | Should -Be 'Archive/2020'
            $r['pipeline.PL_B'] | Should -Be ''
            $r['dataset.DS_A'] | Should -Be 'Sales'
            Should -Invoke Invoke-AzRestMethod -Times 3 -Exactly
        }

        It 'Should follow nextLink' {
            Mock Invoke-AzRestMethod {
                $body = switch -Wildcard ($Uri) {
                    'https://next*' { '{"value":[{"name":"PL_B","properties":{"folder":{"name":"F2"}}}]}' }
                    '*/pipelines?*' { '{"value":[{"name":"PL_A","properties":{"folder":{"name":"F1"}}}],"nextLink":"https://next/page2"}' }
                    default         { '{"value":[]}' }
                }
                [PSCustomObject]@{ StatusCode = 200; Content = $body }
            }
            $r = Get-AdfObjectFolder -adfInstance $script:ins
            $r['pipeline.PL_A'] | Should -Be 'F1'
            $r['pipeline.PL_B'] | Should -Be 'F2'
        }

        It 'Should throw when the API returns an error' {
            Mock Invoke-AzRestMethod { [PSCustomObject]@{ StatusCode = 403; Content = '{}' } }
            { Get-AdfObjectFolder -adfInstance $script:ins } | Should -Throw '*403*'
        }
    }
}
