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
    $script:ResourceGroupName = 'rg-devops-factory'
    $c = Get-AzContext
    $script:guid = $c.Subscription.Id.Substring(0,8)
    $script:DataFactoryOrigName = 'BigFactorySample2'
    $script:DataFactoryName = $script:DataFactoryOrigName + "-$guid"
    $script:SrcFolder = "$PSScriptRoot\$($script:DataFactoryOrigName)"
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)
    Copy-Item -path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.json" -Recurse:$true -Force 
    Write-Host $TmpFolder
    Write-Host $script:RootFolder
    
    $VerbosePreference = 'Continue'
    $script:RootFolder = 'C:\Users\kamil\AppData\Local\Temp\ADFTools-3oirmp1y.vrn\BigFactorySample2'

    Describe 'Prerequisites of Export-AdfToArmTemplate' -Tag 'Unit' {
        It 'no files *.json!' {
            Test-Path -Path "$RootFolder\pipeline\*.json!" | Should -Be $False
        }
    }

    Describe 'Export-AdfToArmTemplate' -Tag 'Unit' {

        It 'Should exist' {
            { Get-Command -Name 'Publish-AdfV2UsingArm' -ErrorAction Stop } | Should -Not -Throw
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

    Describe 'Publish-AdfV2UsingArm' -Tag 'Unit' {
        It 'Should deploy ADF' {
            $ArmFile =      "$RootFolder\ArmTemplate\ARMTemplateForFactory.json"
            $ArmParamFile = "$RootFolder\ArmTemplate\ARMTemplateParametersForFactory.json"
            $rg = 'rg-blog-dev'
            $DataFactoryName = 'adf1-73489375893'
            $o = New-AdfPublishOption
            $o.CreateNewInstance = $true
            $o.StopStartTriggers = $true
            $o.DeployGlobalParams = $true
            { Publish-AdfV2UsingArm -TemplateFile $ArmFile -TemplateParameterFile $ArmParamFile `
                -ResourceGroupName $rg -DataFactory $DataFactoryName -Option $o -Location 'uksouth'
            } | Should -Not -Throw
        }
    }


}
