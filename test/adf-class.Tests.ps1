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

    Describe 'adf class' -Tag 'class' {
        It 'Should exist' {
            { $script:adf = New-Object -TypeName Adf } | Should -Not -Throw
        }

        It 'Should have GetUnusedDatasets method' {
            (Get-Member -InputObject $adf -Name 'GetUnusedDatasets' | Measure-Object).Count | Should -Be 1
        }
        It 'exec GetUnusedDatasets even if adf just created' {
            { $script:adf.GetUnusedDatasets() } | Should -Not -Throw
        }
        

    } 
}
