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
    $t = Get-TargetEnv 'adf-simpledeployment-dev'
    $script:rg = $t.ResourceGroupName
    $script:DataFactoryOrigName = $t.DataFactoryOrigName
    $script:DataFactoryName = $t.DataFactoryName
    $script:Location = $t.Location

    $script:TmpFolder = (New-TemporaryDirectory).FullName
    Copy-Item -Path (Join-Path $PSScriptRoot $DataFactoryOrigName "armtemplate") -Destination "$TmpFolder" -Recurse:$true -Force 
    #Invoke-Expression "explorer.exe '$TmpFolder'"
    $script:ArmFile =      (Join-Path $TmpFolder "armtemplate" "ARMTemplateForFactory.json")
    $script:ArmParamFile = (Join-Path $TmpFolder "armtemplate" "ARMTemplateParametersForFactory.json")
    Edit-TextInFile $script:ArmParamFile $t.DataFactoryOrigName $t.DataFactoryName

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
                -ResourceGroupName $rg -DataFactory $DataFactoryName -Location $Location -Option $o -WhatIf:$false
            } | Should -Not -Throw
        }
    }


}
