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

    Describe 'ConvertFrom-ArraysToOrderedHashTables' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name ConvertFrom-ArraysToOrderedHashTables -ErrorAction Stop } | Should -Not -Throw
        }
    } 

    Describe 'ConvertFrom-OrderedHashTablesToArrays' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name ConvertFrom-OrderedHashTablesToArrays -ErrorAction Stop } | Should -Not -Throw
        }
    } 

    Describe 'ConvertFrom-ArraysToOrderedHashTables' -Tag 'Unit' {
        It 'not fail when empty element found in file' {
            $o = New-AdfObjectFromFile -fileRelativePath 'misc\OB_CosmosDB_sink.json' -type 'dataset' -name 'OB_CosmosDB_sink'
            { $o.Body | ConvertFrom-ArraysToOrderedHashTables } | Should -Not -Throw
        }
    }


}
