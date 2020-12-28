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
    $script:guid =  (New-Guid).ToString().Substring(0,8)
    $script:guid = '5889b15h'
    $script:DataFactoryOrigName = 'BigFactorySample2'
    $script:DataFactoryName = $script:DataFactoryOrigName + "-$guid"
    $script:SrcFolder = ".\$($script:DataFactoryOrigName)"
    $script:Location = "NorthEurope"
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)

    Remove-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName" -Force
    Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.csv" -Recurse:$true -Force 
    #Invoke-Expression "explorer.exe '$TmpFolder'"

    


    Describe 'Publish-AdfV2FromJson' -Tag 'Integration', 'triggers' {

        Context 'Trigger exists in the source only and is excluded from deployment' {
            It 'Should not failed' {
                Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "TR_AlwaysDisabled.json" -Recurse:$true -Force 
                Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "PL_Wait5sec.json" -Recurse:$true -Force 
                $script:opt = New-AdfPublishOption
                #$script:opt.Includes.Add("*.*", "")
                $script:opt.Excludes.Add("*.*", "")
                $script:opt.StopStartTriggers = $true
                { Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" `
                    -Location "$Location" -Option $script:opt -Stage 'c001'   # Trigger enabled
                } | Should -Not -Throw
            }
            It 'Should not deploy object' {
                $script:TriggersOnDiskCount = (Get-ChildItem -Path "$RootFolder\trigger" -Filter "TR_*.json" -Recurse:$true | Measure-Object).Count
                $tr = Get-AzDataFactoryV2Trigger -DataFactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
                $arr = $tr | ToArray
                $script:TriggersInServiceCount = $arr.Count
                $script:TriggersInServiceCount | Should -Be 0
            }
        }
    }
}
