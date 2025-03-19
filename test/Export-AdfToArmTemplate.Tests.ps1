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
    $script:t = Get-TargetEnv 'adf1'
    $script:ResourceGroupName = $t.ResourceGroupName
    $script:DataFactoryOrigName = $t.DataFactoryOrigName
    $script:DataFactoryName = $t.DataFactoryName
    $script:ArmFile =      "$DataFactoryOrigName\armtemplate\ARMTemplateForFactory.json"
    $script:ArmParamFile = "$DataFactoryOrigName\armtemplate\ARMTemplateParametersForFactory.json"
    $script:SrcFolder = "$PSScriptRoot\$($script:DataFactoryOrigName)"
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)
    Copy-Item -path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.json" -Recurse:$true -Force 
    Write-Host $TmpFolder
    Write-Host $script:RootFolder
    #Invoke-Expression "explorer.exe '$TmpFolder'"

    $VerbosePreference = 'Continue'

    Describe 'Prerequisites of Export-AdfToArmTemplate' -Tag 'Unit' {
        It 'no files *.json!' {
            Test-Path -Path "$RootFolder\pipeline\*.json!" | Should -Be $False
        }
    }

    Describe 'Export-AdfToArmTemplate' -Tag 'Unit' {

        It 'Should exist' {
            { Get-Command -Name 'Export-AdfToArmTemplate' -ErrorAction Stop } | Should -Not -Throw
        }
        It 'Should completed successfully' {
            { Export-AdfToArmTemplate -RootFolder $script:RootFolder } | Should -Not -Throw
        }
        It 'Should create folder "ArmTemplate"' {
            Test-Path -Path "$RootFolder\ArmTemplate" | Should -Be $True
        }

        # $cases= 
        # @{ file = 'ARMTemplateForFactory.json' },
        # @{ file = 'ARMTemplateParametersForFactory.json' },
        # @{ file = 'GlobalParametersUpdateScript.ps1' },
        # @{ file = 'PrePostDeploymentScript.ps1' }
        # It 'New folder should contain file "<file>"' -TestCases $cases {
        #     param ($file)
        #     Test-Path -Path "$RootFolder\ArmTemplate\$file" | Should -Be $True
        # }

    }

    Describe 'Publish-AdfV2UsingArm' -Tag 'Integration' {
        It 'Should deploy ADF from generated ARM template files' {
            $ArmFile =      (Join-Path $RootFolder "ArmTemplate" "ARMTemplateForFactory.json")
            $ArmParamFile = (Join-Path $RootFolder "ArmTemplate" "ARMTemplateParametersForFactory.json")
            Edit-TextInFile $ArmParamFile "$($t.DataFactoryOrigName)""" "$($t.DataFactoryName)"""
            $o = New-AdfPublishOption
            $o.CreateNewInstance = $true
            $o.StopStartTriggers = $false
            $o.DeployGlobalParams = $true
            { Publish-AdfV2UsingArm -TemplateFile $ArmFile -TemplateParameterFile $ArmParamFile `
                -ResourceGroupName $t.ResourceGroupName -DataFactory $t.DataFactoryName -Option $o -Location $t.Location
            } | Should -Not -Throw
        }
    }

}
