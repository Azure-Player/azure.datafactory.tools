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
    $script:Stage = 'UAT'
    $c = Get-AzContext
    $script:guid = $c.Subscription.Id.Substring(0,8)
    $script:SrcFolder = "$PSScriptRoot\BigFactorySample2"
    $script:DataFactoryName = (Split-Path -Path $script:SrcFolder -Leaf) + "-$guid"
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
        #     BeforeAll {
        #         Mock Stop-AzDataFactoryV2Trigger { }
        #         $script:adf = Import-AdfFromFolder -FactoryName $script:DataFactoryName -RootFolder "$RootFolder"
        #         $script:adf.ResourceGroupName = "$ResourceGroupName";
        #         $script:adf.PublishOptions = New-AdfPublishOption
        #     }
        #     It 'Should disable only those active' {
        #         Stop-Triggers -adf $adf
        #         $allTriggers = Get-AzDataFactoryV2Trigger -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
        #         $activeTriggers = $allTriggers | Where-Object { $_.RuntimeState -ne "Stopped" } | ToArray
        #         Assert-MockCalled Stop-AzDataFactoryV2Trigger -Times $activeTriggers.Count
        #     }
        # }
        
    } 
}




# https://pester.dev/docs/usage/mocking

