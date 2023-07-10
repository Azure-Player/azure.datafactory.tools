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
    $script:DataFactoryName = "SQLPlayerDemo-$Stage"
    $script:RootFolder = Join-Path -Path "$PSScriptRoot" -ChildPath "BigFactorySample2"
    $script:WrongRootFolder = Join-Path -Path $script:RootFolder -ChildPath "dfij393gfu0AJQ3"
    $script:Location = "NorthEurope"
    
    Describe 'Import-AdfFromFolder' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Import-AdfFromFolder -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'When called with not-existing Folder' {
            It 'Should throw error' {
                { Import-AdfFromFolder -FactoryName $script:DataFactoryName -RootFolder $script:WrongRootFolder -ErrorAction Stop } | Should -Throw
            }
        }

        # Context 'mandatory parameters' {
        #     it 'FactoryName' {
        #         (Get-Command -Name 'Import-AdfFromFolder').Parameters['FactoryName'].Attributes.Mandatory | Should be $true
        #     }
        #     it 'RootFolder' {
        #         (Get-Command -Name 'Import-AdfFromFolder').Parameters['RootFolder'].Attributes.Mandatory | Should be $true
        #     }
        # }
        
        Context 'When called' {
            It 'Should return object of [Adf] type' {
                $script:result = Import-AdfFromFolder -FactoryName $script:DataFactoryName -RootFolder $script:RootFolder
                $script:result.GetType() | Should -Be 'Adf'
            }
            It 'Should return Name, ResourceGroupName, Location with correct values' {
                $script:result.Name | Should -Be "$script:DataFactoryName"
                $script:result.ResourceGroupName | Should -Be ""
                $script:result.Location | Should -Be $script:RootFolder
            }
            It 'Should contains Pipelines prop as ArrayList and # of items matches' {
                $script:result.Pipelines.GetType() | Should -Be 'System.Collections.ArrayList'
                $cnt = 0
                $folder = Join-Path -Path "$script:RootFolder" -ChildPath "pipeline"
                if (Test-Path $folder) { $cnt = ($folder | Get-ChildItem -Recurse:$false -Filter "*.json" | Measure-Object).Count }
                $script:result.Pipelines.Count | Should -Be $cnt
            }
            It 'Should contains LinkedServices prop as ArrayList and # of items matches' {
                $script:result.LinkedServices.GetType() | Should -Be 'System.Collections.ArrayList'
                $cnt = 0
                $folder = Join-Path -Path "$script:RootFolder" -ChildPath "linkedService"
                if (Test-Path $folder) { $cnt = ($folder | Get-ChildItem -Recurse:$false -Filter "*.json" | Measure-Object).Count }
                $script:result.LinkedServices.Count | Should -Be $cnt
            }
            It 'Should contains DataSets prop as ArrayList and # of items matches' {
                $script:result.DataSets.GetType() | Should -Be 'System.Collections.ArrayList'
                $cnt = 0
                $folder = Join-Path -Path "$script:RootFolder" -ChildPath "dataset"
                if (Test-Path $folder) { $cnt = ($folder | Get-ChildItem -Recurse:$false -Filter "*.json" | Measure-Object).Count }
                $script:result.DataSets.Count | Should -Be $cnt
            }
            It 'Should contains DataFlows prop as ArrayList and # of items matches' {
                $script:result.DataFlows.GetType() | Should -Be 'System.Collections.ArrayList'
                $cnt = 0
                $folder = Join-Path -Path "$script:RootFolder" -ChildPath "dataflow"
                if (Test-Path $folder) { $cnt = ($folder | Get-ChildItem -Recurse:$false -Filter "*.json" | Measure-Object).Count }
                $script:result.DataFlows.Count | Should -Be $cnt
            }
            It 'Should contains Triggers prop as ArrayList and # of items matches' {
                $script:result.Triggers.GetType() | Should -Be 'System.Collections.ArrayList'
                $cnt = 0
                $folder = Join-Path -Path "$script:RootFolder" -ChildPath "trigger"
                if (Test-Path $folder) { $cnt = ($folder | Get-ChildItem -Recurse:$false -Filter "*.json" | Measure-Object).Count }
                $script:result.Triggers.Count | Should -Be $cnt
            }
            It 'Should contains IntegrationRuntimes prop as ArrayList and # of items matches' {
                $script:result.IntegrationRuntimes.GetType() | Should -Be 'System.Collections.ArrayList'
                $cnt = 0
                $folder = Join-Path -Path "$script:RootFolder" -ChildPath "integrationRuntime"
                if (Test-Path $folder) { $cnt = ($folder | Get-ChildItem -Recurse:$false -Filter "*.json" | Measure-Object).Count }
                $script:result.IntegrationRuntimes.Count | Should -Be $cnt
            }
            It 'Should contains valid non-ascii character' {
                $o = Get-AdfObjectByName -adf $script:result -name "CADOutput1" -Type "dataset"
                $char = $o.Body.properties.typeProperties.columnDelimiter
                $char | Should -Be ([CHAR][BYTE]166)
                $char.Length | Should -Be 1
            }
            It 'Should discover 4 dependant objects in dataflow' {
                $o = Get-AdfObjectByName -adf $script:result -name "Currency Converter" -Type "dataflow"
                $o.DependsOn.Count | Should -Be 4
            }
        }
        
        Context 'when GetObjectsByFolderName function called' {
            It 'Should run fine' {
                { $script:result.GetObjectsByFolderName("AnyFolder") } | Should -Not -Throw
            }
            It 'Should return list of 2 objects' {
                $list = $script:result.GetObjectsByFolderName("ExternalError")
                $list.Count | Should -Be 2
            }
        }

        Context 'when GetObjectsByFullName function called' {
            It 'Should run fine' {
                { $script:result.GetObjectsByFullName("AnyObject") } | Should -Not -Throw
            }
            It 'Should return list of 2 objects' {
                $list = $script:result.GetObjectsByFullName("dataset.taxi_*")
                $list.Count | Should -Be 2
            }
        }
    }
        
    Describe 'Import-AdfFromFolder' -Tag 'Unit' {
        
        Context 'of adf2' {
            It 'Should completed successfully' {
                $script:RootFolder = "$PSScriptRoot\adf2"
                { $script:result = Import-AdfFromFolder -FactoryName $script:DataFactoryName -RootFolder $script:RootFolder -ErrorAction Stop } | Should -Not -Throw
            }
            It 'Should contains Credentials prop as ArrayList and # of items matches' {
                $script:result.Credentials.GetType() | Should -Be 'System.Collections.ArrayList'
                $cnt = 0
                $folder = Join-Path -Path "$script:RootFolder" -ChildPath "credential"
                if (Test-Path $folder) { $cnt = ($folder | Get-ChildItem -Recurse:$false -Filter "*.json" | Measure-Object).Count }
                $script:result.Credentials.Count | Should -Be $cnt
            }
        }

        Context 'of BigFactorySample2_vnet with properties node' {
            It 'Should completed successfully' {
                $RootFolder = "$PSScriptRoot\BigFactorySample2_vnet"
                { Import-AdfFromFolder -FactoryName $script:DataFactoryName -RootFolder $RootFolder -ErrorAction Stop } | Should -Not -Throw
            }
        }
        Context 'of BigFactorySample2_vnet without properties node' {
            It 'Should completed successfully' {
                $RootFolder = "$PSScriptRoot\BigFactorySample2_vnet"
                $vnetFile = Join-Path $RootFolder 'managedVirtualNetwork\default.json'
                $bf = Backup-File -FileName $vnetFile
                Remove-ObjectPropertyFromFile -FileName $vnetFile -Path 'properties'
                Restore-File -FileName $bf $true
                { Import-AdfFromFolder -FactoryName $script:DataFactoryName -RootFolder $RootFolder -ErrorAction Stop } | Should -Not -Throw
            }

        }

    }
    

}
