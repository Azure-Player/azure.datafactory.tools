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

    # Variables for use in tests
    $script:ResourceGroupName = 'rg-devops-factory'
    $script:Stage = 'UAT'
    $script:DataFactoryName = "SQLPlayerDemo-$Stage"
    $script:RootFolder = $env:ADF_ExampleCode
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
                $folder = Join-Path -Path "$env:ADF_ExampleCode" -ChildPath "pipeline"
                if (Test-Path $folder) { $cnt = ($folder | Get-ChildItem -Recurse:$false -Filter "*.json" | Measure-Object).Count }
                $script:result.Pipelines.Count | Should -Be $cnt
            }
            It 'Should contains LinkedServices prop as ArrayList and # of items matches' {
                $script:result.LinkedServices.GetType() | Should -Be 'System.Collections.ArrayList'
                $cnt = 0
                $folder = Join-Path -Path "$env:ADF_ExampleCode" -ChildPath "LinkedService"
                if (Test-Path $folder) { $cnt = ($folder | Get-ChildItem -Recurse:$false -Filter "*.json" | Measure-Object).Count }
                $script:result.LinkedServices.Count | Should -Be $cnt
            }
            It 'Should contains DataSets prop as ArrayList and # of items matches' {
                $script:result.DataSets.GetType() | Should -Be 'System.Collections.ArrayList'
                $cnt = 0
                $folder = Join-Path -Path "$env:ADF_ExampleCode" -ChildPath "DataSet"
                if (Test-Path $folder) { $cnt = ($folder | Get-ChildItem -Recurse:$false -Filter "*.json" | Measure-Object).Count }
                $script:result.DataSets.Count | Should -Be $cnt
            }
            It 'Should contains DataFlows prop as ArrayList and # of items matches' {
                $script:result.DataFlows.GetType() | Should -Be 'System.Collections.ArrayList'
                $cnt = 0
                $folder = Join-Path -Path "$env:ADF_ExampleCode" -ChildPath "DataFlow"
                if (Test-Path $folder) { $cnt = ($folder | Get-ChildItem -Recurse:$false -Filter "*.json" | Measure-Object).Count }
                $script:result.DataFlows.Count | Should -Be $cnt
            }
            It 'Should contains Triggers prop as ArrayList and # of items matches' {
                $script:result.Triggers.GetType() | Should -Be 'System.Collections.ArrayList'
                $cnt = 0
                $folder = Join-Path -Path "$env:ADF_ExampleCode" -ChildPath "Trigger"
                if (Test-Path $folder) { $cnt = ($folder | Get-ChildItem -Recurse:$false -Filter "*.json" | Measure-Object).Count }
                $script:result.Triggers.Count | Should -Be $cnt
            }
            It 'Should contains IntegrationRuntimes prop as ArrayList and # of items matches' {
                $script:result.IntegrationRuntimes.GetType() | Should -Be 'System.Collections.ArrayList'
                $cnt = 0
                $folder = Join-Path -Path "$env:ADF_ExampleCode" -ChildPath "IntegrationRuntime"
                if (Test-Path $folder) { $cnt = ($folder | Get-ChildItem -Recurse:$false -Filter "*.json" | Measure-Object).Count }
                $script:result.IntegrationRuntimes.Count | Should -Be $cnt
            }

        }
        
    } 
}
