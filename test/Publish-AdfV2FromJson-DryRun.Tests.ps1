BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
    $m = Get-Module -Name 'azure.datafactory.tools'
    $script:verStr = $m.Version.ToString(2) + "." + $m.Version.Build.ToString("000")
}

InModuleScope azure.datafactory.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force

    $m = Get-Module -Name 'azure.datafactory.tools'
    $script:verStr = $m.Version.ToString(2) + "." + $m.Version.Build.ToString("000")

    $script:RootFolder = Join-Path $PSScriptRoot 'adf2'
    $script:ResourceGroupName = 'rg-test'
    $script:DataFactoryName = 'adf-test'
    $script:Location = 'West Europe'

    Describe 'Publish-AdfV2FromJson DryRun incremental deployment' -Tag 'Unit' {
        BeforeEach {
            Mock Get-StateFromStorage {
                [AdfDeploymentState]::new($script:verStr)
            }

            Mock Set-StateToStorage {
            }

            Mock Get-AdfFromService {
                $null
            }
        }

        It 'should still load deployment state from storage when DryRun is enabled' {
            $opt = New-AdfPublishOption
            $opt.IncrementalDeployment = $true
            $opt.IncrementalDeploymentStorageUri = 'https://example.blob.core.windows.net/adftools/folder'
            $opt.StopStartTriggers = $false
            $opt.DeleteNotInSource = $false

            {
                Publish-AdfV2FromJson `
                    -RootFolder $script:RootFolder `
                    -ResourceGroupName $script:ResourceGroupName `
                    -DataFactoryName $script:DataFactoryName `
                    -Location $script:Location `
                    -Option $opt `
                    -DryRun
            } | Should -Not -Throw

            Should -Invoke -CommandName Get-StateFromStorage -Times 1 -Exactly
            Should -Invoke -CommandName Set-StateToStorage -Times 0 -Exactly
        }
    }

    Describe 'DryRun terraform-like plan output' -Tag 'Unit' {
        It 'should classify add, change, destroy and expose DryRunPlan on returned object' {
            $opt = New-AdfPublishOption
            $opt.StopStartTriggers = $false
            $opt.DeleteNotInSource = $true
            $opt.DoNotDeleteExcludedObjects = $false
            $opt.Includes.Add('pipeline.PL_ExecSparkJob', '')

            Mock Get-AdfFromService {
                $target = New-Object -TypeName AdfInstance
                $target.Pipelines = @(
                    [AdfPSPipeline]::new('PL_ExecSparkJob'),
                    [AdfPSPipeline]::new('PL_Obsolete')
                )
                $target
            }

            $result = Publish-AdfV2FromJson `
                -RootFolder $script:RootFolder `
                -ResourceGroupName $script:ResourceGroupName `
                -DataFactoryName $script:DataFactoryName `
                -Location $script:Location `
                -Option $opt `
                -DryRun

            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'DryRunPlan'

            $plan = $result.DryRunPlan
            $plan | Should -Not -BeNullOrEmpty
            $plan.Update | Should -Contain 'pipeline.PL_ExecSparkJob'
            $plan.Delete | Should -Contain 'pipeline.PL_Obsolete'
            $plan.Unchanged | Should -Contain 'dataset.DS_Json'
            $plan.Create.Count | Should -Be 0
        }

        It 'should support -Plan as an alias behavior of -DryRun' {
            $opt = New-AdfPublishOption
            $opt.StopStartTriggers = $false

            Mock Get-AdfFromService {
                $target = New-Object -TypeName AdfInstance
                $target
            }

            $result = Publish-AdfV2FromJson `
                -RootFolder $script:RootFolder `
                -ResourceGroupName $script:ResourceGroupName `
                -DataFactoryName $script:DataFactoryName `
                -Location $script:Location `
                -Option $opt `
                -Plan

            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'DryRunPlan'
            $result.DryRunPlan | Should -Not -BeNullOrEmpty
        }
    }
}