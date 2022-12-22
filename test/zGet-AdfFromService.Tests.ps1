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
    $t = Get-TargetEnv 'adf2'
    $script:adfName = $t.DataFactoryName
    $script:rg      = $t.ResourceGroupName
    
    Describe 'Get-AdfFromService' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Get-AdfFromService -ErrorAction Stop } | Should -Not -Throw
        }
    } 

    Describe 'Get-AdfFromService' -Tag 'Integration' {
        It 'Should execute' {
            Get-AdfFromService -FactoryName $adfName -ResourceGroupName $rg
        }
    } 

}
