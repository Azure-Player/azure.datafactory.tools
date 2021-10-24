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
    
    Describe 'Test-Exceptions' -Tag 'Unit' {
        It 'Test-ErrorNoTermination should not throw error' {
            { Test-ErrorNoTermination } | Should -Not -Throw
        }
        It 'Test-ErrorNoTermination should throw error' {
            { Test-ErrorTermination } | Should -Throw
        }
        It 'Test-Exception should throw error' {
            { Test-Exception } | Should -Throw -ExceptionType ([System.Management.Automation.RuntimeException])
        }
    }
    


}
