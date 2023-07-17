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
    $script:SrcFolder = "$PSScriptRoot\BigFactorySample2"
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)
    $script:DeploymentFolder = Join-Path -Path $script:RootFolder -ChildPath "deployment"
    $script:ConfigFolder = Join-Path -Path $script:SrcFolder -ChildPath "deployment"

    Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.*" -Recurse:$true -Force 
    #Invoke-Expression "explorer.exe '$TmpFolder'"

    Describe 'Update-PropertiesFromFile' -Tag 'Unit','private' {
        It 'Should exist' {
            { Get-Command -Name Update-PropertiesFromFile -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'When called without parameters' {
            It 'Should throw an error' {
                { Update-PropertiesFromFile -Force } | Should -Throw 
            }
        }

        Context 'When called with parameters' {
            $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
            $script:option = New-AdfPublishOption
            $script:adf.PublishOptions = $option
            It 'and adf param is empty should throw an error ' { {
                Update-PropertiesFromFile -stage "uat" -Force
                } | Should -Throw
            }
            It 'and stage param is empty should throw an error ' { {
                Update-PropertiesFromFile -adf $adf -Force
                } | Should -Throw
            }
            It 'and $adf.Location is empty should throw an error ' { {
                $script:adf.Location = ""
                Update-PropertiesFromFile -adf $adf -stage "uat" -Force
                } | Should -Throw
            }
        }

        Context 'When called with stage as short code but file does not exist' {
            $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
            $script:option = New-AdfPublishOption
            $script:adf.PublishOptions = $option
            It 'Should throw an error' { {
                Update-PropertiesFromFile -adf $script:adf -stage "FakeStage"
                } | Should -Throw
            }
        }

        Context 'When called' {
            $script:now = Get-Date
            It 'Should return nothing' {
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $script:option = New-AdfPublishOption
                $script:adf.PublishOptions = $option
                $result = Update-PropertiesFromFile -adf $script:adf -stage "uat"
                $result | Should -Be $null
            }
            It 'Should not modify any files' {
                Start-Sleep -Milliseconds 100
                $modFiles = (Get-ChildItem -Path $RootFolder -Exclude "~*.*" -Filter "*.json" -Recurse:$true | Where-Object {$_.LastWriteTime -gt $now} )
                $modFiles | Should -Be $null
            }
            It 'Should contains properties replaced and correct types' {
                $t = Get-AdfObjectByName -adf $script:adf -name "TR_AlwaysDisabled" -type "Trigger"
                $t.Body.properties.typeProperties.recurrence.interval | Should -Be 2
                $t.Body.properties.typeProperties.recurrence.interval.GetType().Name | Should -Be 'Int32'
                $t.Body.properties.runtimeState | Should -Be 'Started'
                $t.Body.properties.runtimeState.GetType().Name | Should -Be 'String'
            }

        }

        
        Context 'When called and CSV has wrong format' {
            It 'Should throw' {
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $script:option = New-AdfPublishOption
                {
                    $script:adf.PublishOptions = $option
                    Update-PropertiesFromFile -adf $script:adf -stage "badformat"
                } | Should -Throw
            }
            It 'Should contains all properties unchanged' {
                $t = Get-AdfObjectByName -adf $script:adf -name "TR_AlwaysDisabled" -type "Trigger"
                $t.Body.properties.runtimeState | Should -Be 'Stopped'
                $t.Body.properties.typeProperties.recurrence.interval | Should -Be 1
            }
        }

        Context 'When called and CSV contains multiple sub-properties as value' {
            It 'Should complete' {
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $script:option = New-AdfPublishOption
                {
                    $script:adf.PublishOptions = $option
                    Update-PropertiesFromFile -adf $script:adf -stage "c002"
                } | Should -Not -Throw
            }
            It 'Should contains properties replaced and correct types' {
                $t = Get-AdfObjectByName -adf $script:adf -name "PL_Wait_Dynamic" -type "pipeline"
                $t.Body.properties.parameters.WaitInSec.type | Should -Be 'int32'
                $t.Body.properties.parameters.WaitInSec.defaultValue | Should -Be 22
            }
        }

        Context 'When called and CSV with commented rows' {
            It 'Should complete' {
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $script:option = New-AdfPublishOption
                {
                    $script:adf.PublishOptions = $option
                    Update-PropertiesFromFile -adf $script:adf -stage "commented"
                } | Should -Not -Throw
            }
            It 'Should not apply changes for commented rows' {
                $t = Get-AdfObjectByName -adf $script:adf -name "TR_AlwaysDisabled" -type "trigger"
                $t.Body.properties.runtimeState | Should -Be 'Started'
                $t.Body.properties.typeProperties.recurrence.interval | Should -Be 1
            }
        }

        Context 'When called and CSV contains incorrect path' {
            It 'Should throw' {
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $script:option = New-AdfPublishOption
                {
                    $script:adf.PublishOptions = $option
                    Update-PropertiesFromFile -adf $script:adf -stage "c004-wrongpath"
                } | Should -Throw -ExceptionType ([System.Data.DataException])
            }
        }

        Context 'When called and CSV contains incorrect path that can be skipped' {
            It 'Should not throw' {
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $script:option = New-AdfPublishOption
                $option.FailsWhenPathNotFound = $false
                $script:adf.PublishOptions = $option
                {
                    Update-PropertiesFromFile -adf $script:adf -stage "c004-wrongpath"
                } | Should -Not -Throw
            }
        }

        Context 'When called and CSV has extra action (add/remove)' {
            It 'Should complete' {
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $script:option = New-AdfPublishOption
                $script:adf.PublishOptions = $option
                {
                    Update-PropertiesFromFile -adf $script:adf -stage "c005-extra-action"
                } | Should -Not -Throw
            }
            It 'Should contains 1 updated property' {
                $script:ls = Get-AdfObjectByName -adf $script:adf -name "BlobSampleData" -type "linkedService"
                $script:ls.Body.properties.typeProperties.connectionString | Should -Be "DefaultEndpointsProtocol=https;AccountName=sqlplayer2019;EndpointSuffix=core.windows.net;"
            }
            It 'Should contains 1 new property' {
                $script:ls.Body.properties.typeProperties.accountKey | Should -Be "orefoifakerjgi40passwordrjegjorejgorjeogjoreg=="
            }
            It 'Should lost 1 property (removed)' {
                Get-Member -InputObject $script:ls.Body.properties.typeProperties -name "encryptedCredential" -Membertype "Properties" | Should -Be $null
            }
        }

        Context 'When called and CSV has wildcard in object name column' {
            It 'Should complete' {
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $script:option = New-AdfPublishOption
                $script:adf.PublishOptions = $option
                {
                    Update-PropertiesFromFile -adf $script:adf -stage "multiple"
                } | Should -Not -Throw
            }
        }
        Context 'When called and CSV has wildcard in object name column' {
            BeforeEach {
                Mock Update-PropertiesForObject { return 0; }
            }
            It 'Should execute Update-PropertiesForObject 3 times' {
                Update-PropertiesFromFile -adf $script:adf -stage "multiple"
                Assert-MockCalled Update-PropertiesForObject -Times 3
            }
        }

        Context 'When called and CSV has array indexers in object name column' {
            It 'Should complete' {
                # Changing activity names means we cant index into it if another test already ran, so reload the files
                Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.*" -Recurse:$true -Force
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $script:option = New-AdfPublishOption
                $script:adf.PublishOptions = $option
                {
                    Update-PropertiesFromFile -adf $script:adf -stage "array"
                } | Should -Not -Throw
            }
        }
        Context 'When called and CSV has array indexers in object name column' {
            BeforeEach {
                Mock Update-PropertiesForObject { return 0; }
            }
            It 'Should execute Update-PropertiesForObject 4 times' {
                Update-PropertiesFromFile -adf $script:adf -stage "array"
                Assert-MockCalled Update-PropertiesForObject -Times 4
            }
        }
        Context 'When called and CSV has array indexers in object name column' {
            It 'Should update properties of correct activities' {
                # Changing activity names means we cant index into it if another test already ran, so reload the files
                Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.*" -Recurse:$true -Force
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $script:option = New-AdfPublishOption
                $script:adf.PublishOptions = $option

                Update-PropertiesFromFile -adf $script:adf -stage "array"
                $t = Get-AdfObjectByName -adf $script:adf -name "Multiple Waits" -type "Pipeline"
                $t.Body.properties.activities[0].name | Should -Be "Wait Number 1"

                # New check for correct type on arrays passed back. Make sure arrays with multiple elements are not boxed up again (Issue #147)
                $t.Body.properties.activities[1].typeProperties.ifTrueActivities.GetType().BaseType.Name | Should -Be "Array"
                $t.Body.properties.activities[1].typeProperties.ifTrueActivities[0].GetType().BaseType.Name | Should -Be "Object"
                $t.Body.properties.activities[1].typeProperties.ifFalseActivities.GetType().BaseType.Name | Should -Be "Array"
                $t.Body.properties.activities[1].typeProperties.ifTrueActivities[0].GetType().BaseType.Name | Should -Be "Object"
                
                $t.Body.properties.activities[1].typeProperties.ifTrueActivities[0].name | Should -Be "Wait Number 2"
                $t.Body.properties.activities[1].typeProperties.ifTrueActivities[0].typeProperties.waitTimeInSeconds | Should -Be 22
                $t.Body.properties.activities[1].typeProperties.ifTrueActivities[1].name | Should -Be "Wait Number 3"
                $t.Body.properties.activities[1].typeProperties.ifTrueActivities[1].typeProperties.waitTimeInSeconds | Should -Be 33

                $t.Body.properties.activities[2].name | Should -Be "Wait Number 4"
            }
        }
    }

    Describe 'Update-PropertiesFromFile' -Tag 'Unit','private' {
        Context 'When called and CSV contains global parameters to be replaced' {
            It 'Should complete' {
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $script:option = New-AdfPublishOption
                {
                    $script:adf.PublishOptions = $option
                    Update-PropertiesFromFile -adf $script:adf -stage "globalparam1"
                } | Should -Not -Throw
            }
            It 'Should contains gp values replaced' {
                $script:gp = Get-AdfObjectByName -adf $script:adf -name $script:adf.Factories[0].Name -type "factory"
                $script:gp.Body.properties.globalParameters.'GP-String'.value | Should -Be "This text has been replaced"
                $script:gp.Body.properties.globalParameters.'GP-Int'.value | Should -Be 2020
                $script:gp.Body.properties.globalParameters.'GP-Bool'.value | Should -Be $False
            }
            It 'Should contains new gp value & type added' {
                $script:gp = Get-AdfObjectByName -adf $script:adf -name $script:adf.Factories[0].Name -type "factory"
                $script:gp.Body.properties.globalParameters.'NewGlobalParam'.value | Should -Be 2023
                $script:gp.Body.properties.globalParameters.'envName'.value | Should -Be "POC"
                $script:gp.Body.properties.globalParameters.'NewGlobalParam'.type | Should -Be "int"
                $script:gp.Body.properties.globalParameters.'envName'.type | Should -Be "string"
            }
        }
    } 

    Describe 'Update-PropertiesFromFile with JSON' -Tag 'Unit','private','jsonconfig' {
        
        $testCases =  @( @{ configFile = 'config-c100.csv' }, @{ configFile = 'config-c100.json' } )

        $Env:DatabricksClusterId = "0820-210125-test000"
        $Env:Region = "uks"
        $Env:ProjectName = "adft"
        $Env:Environment = "uat"

        Context 'When called and JSON has extra actions' {
            It 'Should complete and has properties updated, added and removed' -TestCases $testCases {
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $script:adf.PublishOptions = New-AdfPublishOption
                {
                    $configFilePath = Join-Path -Path $script:DeploymentFolder -ChildPath "$configFile"
                    Update-PropertiesFromFile -adf $script:adf -stage "$configFilePath"
                } | Should -Not -Throw

                $script:ls = Get-AdfObjectByName -adf $script:adf -name "LS_DataLakeStore" -type "linkedService"
                $script:ls.Body.properties.typeProperties.url | Should -Be "https://datalake$($Env:ProjectName)$($Env:Environment).dfs.core.windows.net/"
                $script:lsdbr = Get-AdfObjectByName -adf $script:adf -name "LS_AzureDatabricks" -type "linkedService"
                $script:lsdbr.Body.properties.typeProperties.existingClusterId | Should -Be "$($Env:DatabricksClusterId)"
                $script:lsdbr.Body.properties.typeProperties.domain | Should -Be "https://$($Env:Region).azuredatabricks.net"
                $script:ls = Get-AdfObjectByName -adf $script:adf -name "LS_AzureKeyVault" -type "linkedService"
                $script:ls.Body.properties.typeProperties.baseUrl | Should -Be "https://keyvault-$($Env:ProjectName)-$($Env:Environment).vault.azure.net/"
                $script:ls = Get-AdfObjectByName -adf $script:adf -name "TR_RunEveryDay" -type "trigger"
                $script:ls.Body.properties.typeProperties.recurrence.startTime | Should -Be "2020-06-01T23:22:11.000Z"

                Get-Member -InputObject $script:lsdbr.Body.properties.typeProperties -name "encryptedCredential" -Membertype "Properties" | Should -Be $null
            }
        }

        Context 'When called and JSON has wildcard in object name column' {
            It 'Should complete' {
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $script:option = New-AdfPublishOption
                $script:adf.PublishOptions = $option
                {
                    Update-PropertiesFromFile -adf $script:adf -stage "$($script:ConfigFolder)\config-multiple.json"
                } | Should -Not -Throw
            }
        }
        # Context 'When called and CSV has wildcard in object name column' {
        #     BeforeEach {
        #         Mock Update-PropertiesForObject { return 0; }
        #     }
        #     It 'Should execute Update-PropertiesForObject 3 times' {
        #         Update-PropertiesFromFile -adf $script:adf -stage "multiple"
        #         Assert-MockCalled Update-PropertiesForObject -Times 3
        #     }
        # }


    } 


    Describe 'Update-PropertiesFromFile with JSON' -Tag 'Unit','private' {
        Context 'When called with FailsWhenConfigItemNotFound = $true' {
            It 'Should not throw when object exists' {
                {
                    $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                    $script:option = New-AdfPublishOption
                    $option.FailsWhenConfigItemNotFound = $true
                    $script:adf.PublishOptions = $option
                    Update-PropertiesFromFile -Adf $adf -stage ( Join-Path -Path $script:ConfigFolder -ChildPath "config-c100.csv" )
                } | Should -Not -Throw
            }
            It 'Should throw when object is missing' {
                {
                    $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                    $script:option = New-AdfPublishOption
                    $option.FailsWhenConfigItemNotFound = $true
                    $script:adf.PublishOptions = $option
                    Update-PropertiesFromFile -Adf $adf -stage ( Join-Path -Path $script:ConfigFolder -ChildPath "config-missing.csv" )
                } | Should -Throw
            }
        }

        Context 'When called with FailsWhenConfigItemNotFound = $false' {
            It 'Should not throw when object exists' {
                {
                    $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                    $script:option = New-AdfPublishOption
                    $option.FailsWhenConfigItemNotFound = $false
                    $script:adf.PublishOptions = $option
                    Update-PropertiesFromFile -Adf $adf -stage ( Join-Path -Path $script:ConfigFolder -ChildPath "config-c100.csv" )
                } | Should -Not -Throw
            }
             It 'Should not throw when object is missing' {
                {
                    $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                    $script:option = New-AdfPublishOption
                    $option.FailsWhenConfigItemNotFound = $false
                    $script:adf.PublishOptions = $option
                    Update-PropertiesFromFile -Adf $adf -stage ( Join-Path -Path $script:ConfigFolder -ChildPath "config-missing.csv" )
                } | Should -Not -Throw
             }
        }



    }

    Describe 'Publish-AdfV2FromJson with DryRun' -Tag 'Unit','private' {

        $cases =  @( @{ configFile = 'config-endpoint.csv' }, @{ configFile = 'config-endpoint2.json' } )

        It 'should update vnet-related objects from <configFile>' -TestCases $cases {
            $DataFactoryName = "BigFactorySample2_vnet"
            $RootFolder = Join-Path -Path $PSScriptRoot -ChildPath $DataFactoryName
            $cfgFile = Join-Path -Path $RootFolder -ChildPath "deployment\$configFile"
            { Publish-AdfV2FromJson -RootFolder $RootFolder -DryRun -Stage $cfgFile -ResourceGroupName 'xxx' -DataFactoryName 'abc' } | Should -Not -Throw
        }
    }

}
