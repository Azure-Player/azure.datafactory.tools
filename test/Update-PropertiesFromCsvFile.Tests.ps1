[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
[CmdletBinding()]
param
(
    [Parameter()]
    [System.String]
    $ModuleRootPath = (Get-Location)
)

$moduleManifestName = 'azure.datafactory.tools.psd1'
$moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

Import-Module -Name $moduleManifestPath -Force -Verbose:$false

InModuleScope azure.datafactory.tools {
    #$testHelperPath = $PSScriptRoot | Split-Path -Parent | Join-Path -ChildPath 'TestHelper'
    #Import-Module -Name $testHelperPath -Force
    . ".\test\New-TempDirectory.ps1"

    # Variables for use in tests
    $script:SrcFolder = $env:ADF_ExampleCode
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)

    Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.*" -Recurse:$true -Force 
    #Invoke-Expression "explorer.exe '$TmpFolder'"

    Describe 'Update-PropertiesFromCsvFile' -Tag 'Unit','private' {
        It 'Should exist' {
            { Get-Command -Name Update-PropertiesFromCsvFile -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'When called without parameters' {
            It 'Should throw an error' {
                { Update-PropertiesFromCsvFile } | Should -Throw 
            }
        }

        Context 'When called with parameters' {
            $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
            It 'and adf param is empty should throw an error ' { {
                Update-PropertiesFromCsvFile -stage "uat" -Force
                } | Should -Throw 
            }
            It 'and stage param is empty should throw an error ' { {
                Update-PropertiesFromCsvFile -adf $adf -Force
                } | Should -Throw 
            }
            It 'and $adf.Location is empty should throw an error ' { {
                $script:adf.Location = ""
                Update-PropertiesFromCsvFile -adf $adf -stage "uat" -Force
                } | Should -Throw 
            }
        }

        Context 'When called with stage as short code but file does not exist' {
            $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
            It 'Should throw an error' { {
                Update-PropertiesFromCsvFile -adf $script:adf -stage "FakeStage"
                } | Should -Throw 
            }
        }

        Context 'When called' {
            $script:now = Get-Date
            It 'Should return nothing' {
                $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                $result = Update-PropertiesFromCsvFile -adf $script:adf -stage "UAT"
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
                {
                    Update-PropertiesFromCsvFile -adf $script:adf -stage "badformat"
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
                {
                    Update-PropertiesFromCsvFile -adf $script:adf -stage "c002"
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
                {
                    Update-PropertiesFromCsvFile -adf $script:adf -stage "commented"
                } | Should -Not -Throw
            }
            It 'Should not apply changes for commented rows' {
                $t = Get-AdfObjectByName -adf $script:adf -name "TR_AlwaysDisabled" -type "trigger"
                $t.Body.properties.runtimeState | Should -Be 'Started'
                $t.Body.properties.typeProperties.recurrence.interval | Should -Be 1
            }
        }

    } 
}
