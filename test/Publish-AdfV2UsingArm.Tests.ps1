BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force

    $testPath = Get-RootPath
    Set-Location $testPath

    # Variables for use in tests
    $script:DataFactoryName = 'adf-simpledeployment-dev'
    $script:ArmFile =      "$DataFactoryName\armtemplate\ARMTemplateForFactory.json"
    $script:ArmParamFile = "$DataFactoryName\armtemplate\ARMTemplateParametersForFactory.json"
    $script:rg = 'rg-blog-dev'

    Describe 'Publish-AdfV2UsingArm' -Tag 'Integration' {

        It 'Should exist' {
            { Get-Command -Name 'Publish-AdfV2UsingArm' -ErrorAction Stop } | Should -Not -Throw
        }
        It 'Should run successfully' {
            $o = New-AdfPublishOption
            $o.CreateNewInstance = $true
            $o.StopStartTriggers = $false
            $o.DeployGlobalParams = $false
            { Publish-AdfV2UsingArm -TemplateFile $ArmFile -TemplateParameterFile $ArmParamFile `
                -ResourceGroupName $rg -DataFactory $DataFactoryName -Option $o -WhatIf:$false
            } | Should -Not -Throw
        }
    }


}
