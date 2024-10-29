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
    $script:t = Get-TargetEnv 'BigFactorySample2'
    $script:ResourceGroupName = $t.ResourceGroupName
    $script:DataFactoryOrigName = $t.DataFactoryOrigName
    $script:DataFactoryName = $t.DataFactoryName
    $script:Location = $t.Location
    $script:adfi = Get-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName"
    #$script:RootFolder = Join-Path $PSScriptRoot "BigFactorySample2"

    $script:opt = New-AdfPublishOption
    $opt.IncrementalDeployment = $true
    $opt.Includes.Add("*.TR_RunEveryDay", "")
    $opt.Includes.Add("*.PL_wait5sec", "")
    $opt.Includes.Add("factory.*", "")

    $script:SrcFolder = "$PSScriptRoot\$($script:DataFactoryOrigName)"
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)
    Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.*" -Recurse:$true -Force 


    Describe 'Get-AzDFV2Credential' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Get-AzDFV2Credential -ErrorAction Stop } | Should -Not -Throw
        }
        It 'Should run successfully' {
            { Get-AzDFV2Credential -adfi $adfi | ToArray } | Should -Not -Throw
        }
    } 

    Describe 'Publish-AdfV2FromJson' {
        It 'BigFactorySample2 should deploy credential object successfully' {
            $o = New-AdfPublishOption
            $o.StopStartTriggers = $false
            $o.Includes.Add("cred*.*", "")
            $o.Includes.Add("linked*.ls_azurekeyvault", "")
            Publish-AdfV2FromJson -RootFolder $RootFolder -ResourceGroupName $script:ResourceGroupName `
                -Location $script:Location -DataFactoryName $script:DataFactoryName -Option $o
        }
        It 'must return credential object after deployment' {
            $crs = Get-AzDFV2Credential -adfi $adfi | ToArray
            $crs.Count | Should -Be 1
        }
    }

    Describe 'Publish-AdfV2FromJson' -Tag 'Integration', 'IncrementalDeployment' {

        It 'Should run successfully even when no Global Params are in target (new) ADF' {
            $opt.IncrementalDeployment = $true
            $opt.CreateNewInstance = $true
            $opt.StopStartTriggers = $false
            Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                -ResourceGroupName "$ResourceGroupName" `
                -DataFactoryName "$DataFactoryName" `
                -Location "$Location" -Option $opt
        }
        # This is no longer valid as new version keep state in Storage, not in ADF
        # It 'New GP "adftools_deployment_state" should exist' {
        #     $f = Get-AzDataFactoryV2 -ResourceGroupName $t.ResourceGroupName -DataFactoryName $t.DataFactoryName
        #     $f.GlobalParameters.Keys.Contains("adftools_deployment_state") | Should -Be $true
        # }

        It 'Should run successfully even when no Global Params are in target (exists) ADF' {
            Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                -ResourceGroupName "$ResourceGroupName" `
                -DataFactoryName "$DataFactoryName" `
                -Location "$Location" -Option $opt
        }
    }

    Describe 'Publish-AdfV2FromJson' -Tag 'Integration', 'IncrementalDeployment' {

        BeforeEach {
            $VerbosePreference = 'Continue'
            Mock Deploy-AdfObject {
                param ($obj)
                if ($obj.Type -eq 'factory') {
                    if ($obj.Body.properties.globalParameters | Get-Member -MemberType NoteProperty -Name 'adftools_deployment_state') {
                        $ds = (Get-Content -Path "test\misc\adftools_deployment_state.json" -Raw -Encoding 'utf8') | ConvertFrom-Json
                        for ($i = 1000; $i -lt 3001; $i++) {
                            Add-ObjectProperty -obj $ds -path "Deployed.pipeline$i" -value "00000000000000000000000000000000"
                        }
                        $obj.Body.properties.globalParameters.adftools_deployment_state.type = "object"
                        $obj.Body.properties.globalParameters.adftools_deployment_state.value = $ds
                        Save-AdfObjectAsFile -obj $obj
                    }
                    Deploy-AdfObjectOnly -obj $obj
                }
            }
        }
        It 'Should deploy successfully even big size of global parameters' { 
            $opt.StopStartTriggers = $false
            Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                -ResourceGroupName "$ResourceGroupName" `
                -DataFactoryName "$DataFactoryName" `
                -Location "$Location" -Option $opt
        }

    }

    Describe 'Publish-AdfV2FromJson' -Tag 'Integration', 'IncrementalDeployment' {

        BeforeEach {
            Mock Stop-AzDataFactoryV2Trigger {
                param ($ResourceGroupName, $DataFactoryName, $Name)
            }
            Mock Remove-AzDataFactoryV2Trigger {
                param ($ResourceGroupName, $DataFactoryName, $Name)
            }
        }

        It 'Should have 1 trigger active' {
            Start-AzDataFactoryV2Trigger -ResourceGroupName $t.ResourceGroupName -DataFactoryName $t.DataFactoryName -Name 'TR_RunEveryDay' -Force
            $t = Get-AzDataFactoryV2Trigger -ResourceGroupName $t.ResourceGroupName -DataFactoryName $t.DataFactoryName -Name 'TR_RunEveryDay'
            $t.RuntimeState | Should -Be 'Started'
        }

        It 'Should disable and delete trigger when TriggerStartMethod = KeepPreviousState' {
            Remove-Item -Path "$RootFolder\trigger\*" -Filter "*.json" -Force
            $opt.DeleteNotInSource = $true
            $opt.StopStartTriggers = $true
            $opt.TriggerStopMethod = 'DeployableOnly'
            $opt.TriggerStartMethod = 'KeepPreviousState'
            Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                -ResourceGroupName "$ResourceGroupName" `
                -DataFactoryName "$DataFactoryName" `
                -Location "$Location" -Option $opt
            Assert-MockCalled Stop-AzDataFactoryV2Trigger -Times 1
            Assert-MockCalled Remove-AzDataFactoryV2Trigger -Times 1
        }



    }


}
