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

    Describe 'Test-AdfCode' -Tag 'Unit' {
        It 'Should run successfully even for empty factory' {
            $DataFactoryName = "emptyFactory"
            $RootFolder = Join-Path -Path $PSScriptRoot -ChildPath $DataFactoryName
            { Test-AdfCode $RootFolder } | Should -Not -Throw
        }

    } 


    Describe 'Test-AdfCode' -Tag 'Unit' {
        It 'Should not throw error due to missing file' {
            $DataFactoryName = "BigFactorySample2_vnet"
            $RootFolder = Join-Path -Path $PSScriptRoot -ChildPath $DataFactoryName
            { 
                $script:res = Test-AdfCode -RootFolder $RootFolder
            } | Should -Not -Throw
        }
        It 'Should return 1 error' {
            $res | Should -Be 1
        }

    }
}
