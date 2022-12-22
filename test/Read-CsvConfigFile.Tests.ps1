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
    $script:SrcFolder = Join-Path $PSScriptRoot "BigFactorySample2"
    $script:ConfigFolder = Join-Path -Path $script:SrcFolder -ChildPath "deployment"
    $Env:NUMBER_OF_PROCESSORS = 6

    Describe 'Read-CsvConfigFile' -Tag 'Unit','private' {
        It 'Should exist' {
            { Get-Command -Name Read-CsvConfigFile -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'When called without parameters' {
            It 'Should throw an error' {
                { Read-CsvConfigFile -Force } | Should -Throw 
            }
        }

        Context 'When called' {
            It 'Should return Array object' {
                $result = Read-CsvConfigFile -Path ( Join-Path -Path $script:ConfigFolder -ChildPath "config-c001.csv" )
                $result | Should -Not -Be $null
                $result.GetType() | Should -Be 'System.Object[]'
            }
            It 'Validation should fail if the file has wrong format' {
                {
                    Read-CsvConfigFile -Path ( Join-Path -Path $script:ConfigFolder -ChildPath "config-badformat.csv" )
                } | Should -Throw -ExceptionType ([System.Data.DataException])
            }
            It 'Validation should fail if the file contains incorrect type of object' {
                {
                    Read-CsvConfigFile -Path ( Join-Path -Path $script:ConfigFolder -ChildPath "config-badtype.csv" )
                } | Should -Throw -ExceptionType ([System.Data.DataException])
            }
            It 'Validation should complete even if the file contains commented and empty lines' {
                {
                    Read-CsvConfigFile -Path ( Join-Path -Path $script:ConfigFolder -ChildPath "config-commented.csv" )
                } | Should -Not -Throw 
            }

        }

        Context 'When called and CSV contains tokens to be replaced by environment variables' {
            It 'Should complete' {
                {
                    $Env:SYSTEM_STAGEDISPLAYNAME = "dev"
                    $script:csv = Read-CsvConfigFile -Path ( Join-Path -Path $script:ConfigFolder -ChildPath "config-c003-variables.csv" )
                } | Should -Not -Throw
            }
            It 'Should contains column value replaced' {
                $csv[0].value | Should -Be 'Started'
                $csv[1].value | Should -Be $Env:NUMBER_OF_PROCESSORS
                $csv[2].value | Should -Be "https://kv-devStage.vault.azure.net/"
                $csv[3].value | Should -Be "Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=$Env:USERDOMAIN.database.windows.net;Initial Catalog=AdventureWorks2014;User ID=$Env:USERNAME@$Env:USERDOMAIN"
            }
        }


    } 
}
