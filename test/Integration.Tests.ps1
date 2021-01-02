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
    $script:SrcFolder = "$PSScriptRoot\$($script:DataFactoryOrigName)"
    $script:Location = "NorthEurope"
    $script:AllExcluded = (New-AdfPublishOption)
    $script:AllExcluded.Excludes.Add('*','')
    $script:AllExcluded.StopStartTriggers = $false
    $script:AllExcluded.DeleteNotInSource = $false
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)
    $script:FinalOpt = New-AdfPublishOption
    # $RootFolder = "c:\Users\kamil\AppData\Local\Temp\24zet2bv.qvg\BigFactorySample2"

    Remove-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName" -Force
    Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.csv" -Recurse:$true -Force 
    #Invoke-Expression "explorer.exe '$TmpFolder'"

    Describe 'Publish-AdfV2FromJson' -Tag 'Integration', 'adf' {
        # It 'Folder should exist' {
        #     { Get-Command -Name Import-AdfFromFolder -ErrorAction Stop } | Should -Not -Throw
        # }

        Context 'when does not exist and called without Location' {
            It 'Throw error #1' {
                { Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" } | Should -Throw
            }
        }

        Context 'when does not exist and called with option CreateNewInstance=false' {
            It 'Throw error #2' {
                { 
                    $opt = New-AdfPublishOption
                    $opt.CreateNewInstance = $false
                    Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" `
                    -Location "$Location" -Option $opt } | Should -Throw
            }
        }

        Context 'when does not exist and called with Location but without objects' {
            It 'Should create new ADF instance' {
                $script:result = Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" -Location "$Location" 
            }
            It 'New instance should have no objects and valid properties' {
                $adfService = Get-AdfFromService -ResourceGroupName "$ResourceGroupName" -FactoryName "$DataFactoryName"
                $adfService.GetType() | Should -Be 'AdfInstance'
                $adfService.AllObjects().Count | Should -Be 0
                $adfService.Name | Should -Not -BeNullOrEmpty
                $adfService.Location | Should -Not -BeNullOrEmpty
                $adfService.ResourceGroupName | Should -Not -BeNullOrEmpty
                $adfService.Name | Should -Be "$DataFactoryName"
                $adfService.Location | Should -Be "$Location"
                $adfService.ResourceGroupName | Should -Be "$ResourceGroupName"
            }
        }

        #Context 'when does not exist and called with Location and Option Exclude all' {

        Context 'ADF exist and publish 1 new pipeline' {
            It 'Should contains 1 pipeline' {
                $PipelineName = "PL_Wait5sec"
                Copy-Item -path "$SrcFolder" -Destination "$TmpFolder" -Filter "$PipelineName.json" -Recurse:$true -Force 
                #Get-ChildItem -Path $RootFolder -Recurse:$true
                Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" -Location "$Location" 
                #$adfService = Get-AdfFromService -ResourceGroupName "$ResourceGroupName" -FactoryName "$DataFactoryName"
                $pipelines = Get-AzDataFactoryV2Pipeline -DataFactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
                $pipelines.Name | Should -Be $PipelineName
            }
        }

        Context 'when waitTimeInSeconds in Wait Activity contains expression instead of Int32' {
            It 'Deployment of contained pipeline fails (until Microsoft will not fix it)' { #{
                $PipelineName = "PL_Wait_Dynamic"
                $script:FinalOpt.Excludes.Add("*.$PipelineName","")
                # Copy-Item -path "$SrcFolder" -Destination "$TmpFolder" -Filter "$PipelineName.json" -Recurse:$true -Force 
                # Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                #     -ResourceGroupName "$ResourceGroupName" `
                #     -DataFactoryName "$DataFactoryName" -Location "$Location" -Method "AzDataFactory"
                # } | Should -Throw
            }
        }
        
        Context 'when publishing Triggers' {
            It 'Enabled trigger should be deployed and Started' {
                $TriggerName = "TR_RunEveryDay"
                Copy-Item -path "$SrcFolder" -Destination "$TmpFolder" -Filter "$TriggerName.json" -Recurse:$true -Force 
                Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" -Location "$Location" 
                $tr = Get-AzDataFactoryV2Trigger -DataFactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName" -Name "$TriggerName"
                $tr.Name | Should -Be $TriggerName
                $tr.RuntimeState | Should -Be "Started"
            }

            It 'Disabled trigger but enabled by config should be deployed and Started' {
                $TriggerName = "TR_AlwaysDisabled"
                Copy-Item -path "$SrcFolder" -Destination "$TmpFolder" -Filter "$TriggerName.json" -Recurse:$true -Force 
                Copy-Item -path "$SrcFolder" -Destination "$TmpFolder" -Filter "config-c001.csv" -Recurse:$true -Force 
                Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" -Location "$Location" -Stage "c001"
                $tr = Get-AzDataFactoryV2Trigger -DataFactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName" -Name "$TriggerName"
                $tr.Name | Should -Be $TriggerName
                $tr.RuntimeState | Should -Be "Started"
                $tr.Properties.Recurrence.Interval | Should -Be 2
            }

        }



        
        Context 'ADF exist and publish whole ADF (except SharedIR)' {
            It 'Should finish successfully' {
                Copy-Item -path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.json" -Recurse:$true -Force 
                $script:AllFilesCount = (Get-ChildItem -Path "$TmpFolder" -Filter "*.json" -Recurse:$true | `
                    Where-Object { !$_.Name.StartsWith('~') } | `
                    Where-Object { !$_.Name.StartsWith('config-') } | `
                    Measure-Object).Count
                $script:FinalOpt.Excludes.Add("*.SharedIR*","")
                $script:FinalOpt.Excludes.Add("*.LS_SqlServer_DEV19_AW2017","")
                $script:FinalOpt.Excludes.Add("factory.*","")   # Global properties
                $script:ExcludeCount = $script:FinalOpt.Excludes.Count
                { Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $script:FinalOpt
                } | Should -Not -Throw
            }
            It "Should contains the same number of objects as files subtract few excluded" {
                $adfIns = Get-AdfFromService -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
                $adfIns.AllObjects().Count | Should -Be ($script:AllFilesCount - $script:ExcludeCount)
            }
        }

        Context 'ADF fully published and redeploy deleting all with DeleteNotInSource=true' {
            It 'Should complete successfully' {
                Remove-Item -Path "$RootFolder\*" -Recurse:$true -Force
                $script:AllExcluded.DeleteNotInSource = $true
                { Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" -Option $script:AllExcluded
                } | Should -Not -Throw

            }
        }

    } 


    Describe 'Publish-AdfV2FromJson and DeployGlobalParams=true' -Tag 'Integration', 'global' {
        Context 'But factory folder does not exist' {
            It 'Should run successfully' {
                $script:opt = New-AdfPublishOption
                $script:opt.Excludes.Add("*.*", "")
                $script:opt.Includes.Add("factory.*", "")
                $script:opt.DeployGlobalParams = $true
                $script:opt.StopStartTriggers = $false
                {
                    Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                        -ResourceGroupName "$ResourceGroupName" `
                        -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $script:opt 
                } | Should -Not -Throw
            }
        }
        Context 'factory folder exists and some global params exist' {
            It 'Should run and deploy 6 global properties' {
                Copy-Item -path "$SrcFolder" -Destination "$TmpFolder" -Filter "$($script:DataFactoryOrigName).json" -Recurse:$true -Force 
                $adf = Import-AdfFromFolder -FactoryName "$($script:DataFactoryName)" -RootFolder "$RootFolder"
                $gp = $adf.Factories[0].Body.properties.globalParameters
                Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $script:opt 
                $adfi = Get-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName"
                $adfi.GlobalParameters.Count | Should -Be 6
                $adfi.GlobalParameters.'GP-String'.Type | Should -Be $gp.'GP-String'.type
                $adfi.GlobalParameters.'GP-String'.Value | Should -Be $gp.'GP-String'.value
                $adfi.GlobalParameters.'GP-Int'.Type | Should -Be $gp.'GP-Int'.type
                $adfi.GlobalParameters.'GP-Int'.Value | Should -Be $gp.'GP-Int'.value
                $adfi.GlobalParameters.'GP-Float'.Type | Should -Be $gp.'GP-Float'.type
                $adfi.GlobalParameters.'GP-Float'.Value | Should -Be $gp.'GP-Float'.value
                $adfi.GlobalParameters.'GP-Bool'.Type | Should -Be $gp.'GP-Bool'.type
                $adfi.GlobalParameters.'GP-Bool'.Value | Should -Be $gp.'GP-Bool'.value
                $adfi.GlobalParameters.'GP-Object'.Type | Should -Be $gp.'GP-Object'.type
                $adfi.GlobalParameters.'GP-Object'.Value | Should -Be $gp.'GP-Object'.value
                $adfi.GlobalParameters.'GP-Array'.Type | Should -Be $gp.'GP-Array'.type
                #$adfi.GlobalParameters.'GP-Array'.Value | Should -Be $gp.'GP-Array'.value # This is known bug
            }
        }
        Context 'factory folder exists but no global params exist' {
            It 'Should run successfully' {
                Remove-Item -Path "$RootFolder\factory\*.*"
                Copy-Item -path "$SrcFolder" -Destination "$TmpFolder" -Filter "$($script:DataFactoryOrigName)-without-gp.json#" -Recurse:$true -Force 
                Rename-Item -Path "$RootFolder\factory\$($script:DataFactoryOrigName)-without-gp.json#" -NewName "$($script:DataFactoryOrigName)-without-gp.json"
                $opt = New-AdfPublishOption
                $opt.Excludes.Add("*.*", "")
                $opt.Includes.Add("factory*.*", "")
                {
                    Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                        -ResourceGroupName "$ResourceGroupName" `
                        -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $script:opt 
                } | Should -Not -Throw
            }
        }
        
    }



    Describe 'Publish-AdfV2FromJson' -Tag 'Integration', 'ir' {
        Context 'when publishing Azure IR' {
            It 'All properties should be deployed properly' {
                $obName = "AzureIR"
                Copy-Item -path "$SrcFolder" -Destination "$TmpFolder" -Filter "$obName.json" -Recurse:$true -Force 
                $script:opt = New-AdfPublishOption
                $script:opt.Includes.Add("*.$obName", "")
                Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" -Location "$Location" -Method "AzDataFactory" -Option $script:opt
                $ir = Get-AzDataFactoryV2IntegrationRuntime -DataFactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName" -Name "$obName"
                $ir.Name | Should -Be $obName
                $ir.DataFlowTimeToLive | Should -Be 15
                $ir.DataFlowComputeType | Should -Be "General"
                $ir.DataFlowCoreCount | Should -Be 8
                $ir.Location | Should -Be "North Europe"
                $ir.Description | Should -Be "NorthEurope region"
            }
        }
        
    }

    Describe 'Publish-AdfV2FromJson' -Tag 'Integration', 'triggers' {
        Context 'when deploy all triggers' {
            It 'Should contains the same number of files in trigger folder' {
                Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "PL_Wait5sec.json" -Recurse:$true -Force 
                Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "TR_*.json" -Recurse:$true -Force 
                $script:opt = New-AdfPublishOption
                $script:opt.Includes.Add("trigger.*", "")
                $script:opt.Includes.Add("*.PL_Wait5sec", "")
                Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" `
                    -Location "$Location" -Option $script:opt
                $script:TriggersOnDiskCount = (Get-ChildItem -Path "$RootFolder\trigger" -Filter "TR_*.json" -Recurse:$true | Measure-Object).Count
                $tr = Get-AzDataFactoryV2Trigger -DataFactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
                $arr = $tr | ToArray
                $script:TriggersInServiceCount = $arr.Count
                $arr.Count | Should -Be $script:TriggersOnDiskCount
            }
        }
        Context 'when run Stop-Triggers and files are in source' {
            It 'All triggers in service should be stopped afterwards' {
                $adf = Import-AdfFromFolder -FactoryName $script:DataFactoryName -RootFolder "$RootFolder"
                $adf.ResourceGroupName = "$ResourceGroupName";
                $adf.PublishOptions = New-AdfPublishOption
                Stop-Triggers -adf $adf
                $tr = Get-AzDataFactoryV2Trigger -DataFactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
                $notstopped = ($tr | Where-Object { $_.RuntimeState -ne "Stopped" } | ToArray)
                $notstopped.Count | Should -Be 0
                Start-Triggers -adf $adf
            }
        }
        Context 'when run Stop-Triggers and no files in source' {
            It 'All triggers in service should be stopped afterwards' {
                Remove-Item -Path "$RootFolder\trigger\*" -Filter "TR_RunEveryDay.json" -Force
                Remove-Item -Path "$RootFolder\trigger\*" -Filter "TR_TumblingWindow.json" -Force 
                $script:TriggersOnDiskCount -= 2
                $adf = Import-AdfFromFolder -FactoryName $script:DataFactoryName -RootFolder "$RootFolder"
                $adf.ResourceGroupName = "$ResourceGroupName";
                $adf.PublishOptions = New-AdfPublishOption
                Stop-Triggers -adf $adf
                $tr = Get-AzDataFactoryV2Trigger -DataFactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
                $notstopped = ($tr | Where-Object { $_.RuntimeState -ne "Stopped" } | ToArray)
                $notstopped.Count | Should -Be 0
            }
        }
        Context 'when 2 triggers dissapear and option DeleteNotInSource=false' {
            It 'Number of triggers in service should remain untouched' {
                $script:opt.DeleteNotInSource = $false
                Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" `
                    -Location "$Location" -Option $opt
                $tr = Get-AzDataFactoryV2Trigger -DataFactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
                $arr = $tr | ToArray
                $arr.Count | Should -Be $script:TriggersInServiceCount
            }
        }
        Context 'when 2 triggers dissapear and option DeleteNotInSource=true' {
            It 'Number of triggers in service should decreases by 2' {
                $script:opt.DeleteNotInSource = $true
                Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" `
                    -Location "$Location" -Option $script:opt
                $tr = Get-AzDataFactoryV2Trigger -DataFactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
                $arr = $tr | ToArray
                $arr.Count | Should -Be $script:TriggersOnDiskCount
            }
        }
        Context 'When called and 3 triggers are in service' {
            Mock Stop-AzDataFactoryV2Trigger { }
            $script:adf = Import-AdfFromFolder -FactoryName $script:DataFactoryName -RootFolder "$RootFolder"
            $script:adf.ResourceGroupName = "$ResourceGroupName";

            It 'Should disable only those active' {
                Stop-Triggers -adf $script:adf
                $allTriggers = Get-AzDataFactoryV2Trigger -DataFactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
                $activeTriggers = $allTriggers | Where-Object { $_.RuntimeState -ne "Stopped" } | ToArray
                Assert-MockCalled Stop-AzDataFactoryV2Trigger -Times $activeTriggers.Count
            }
        }


    }
}
