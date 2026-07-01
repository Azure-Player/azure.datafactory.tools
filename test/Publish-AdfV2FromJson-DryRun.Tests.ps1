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
}