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
    $script:SrcFolder = "$PSScriptRoot\adf-simpledeployment-dev"

    Describe 'Test-AdfArmTemplate' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Test-AdfArmTemplate -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should run fine' {
            $path = $script:SrcFolder + '\armtemplate\ARMTemplateForFactory.json'
            { Test-AdfArmTemplate $path } | Should -Not -Throw
        }

    } 
}




