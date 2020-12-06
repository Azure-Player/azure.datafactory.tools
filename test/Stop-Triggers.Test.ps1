BeforeDiscovery {
    $ModuleRootPath = (Get-Location)
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {
    #$testHelperPath = $PSScriptRoot | Split-Path -Parent | Join-Path -ChildPath 'TestHelper'
    #Import-Module -Name $testHelperPath -Force

    . ".\test\New-TempDirectory.ps1"

    # Variables for use in tests
    $script:ResourceGroupName = 'rg-devops-factory'
    $script:Stage = 'UAT'
    $script:guid =  (New-Guid).ToString().Substring(0,8)
    $script:guid = '5889b15h'
    $script:DataFactoryName = (Split-Path -Path $env:ADF_ExampleCode -Leaf) + "-$guid"
    $script:SrcFolder = $env:ADF_ExampleCode
    $script:Location = "NorthEurope"
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)

    Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "###" -Recurse:$true -Force 
    #Invoke-Expression "explorer.exe '$TmpFolder'"


    Describe 'Stop-Triggers' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Stop-Triggers -ErrorAction Stop } | Should -Not -Throw
        }

        # Context 'When called and 3 triggers are in service' {
        #     Mock Stop-AzDataFactoryV2Trigger { }
        #     $adf = Import-AdfFromFolder -FactoryName $script:DataFactoryName -RootFolder "$RootFolder"
        #     $adf.ResourceGroupName = "$ResourceGroupName";

        #     It 'Should disable only those active' {
        #           Stop-Triggers -adf $adf
        #         $allTriggers = Get-AzDataFactoryV2Trigger -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
        #         $activeTriggers = $allTriggers | Where-Object { $_.RuntimeState -ne "Stopped" } | ToArray
        #         Assert-MockCalled Stop-AzDataFactoryV2Trigger -Times $activeTriggers.Count
        #     }
        # }
        
    } 
}




# https://pester.dev/docs/usage/mocking

