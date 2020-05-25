[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
[CmdletBinding()]
param
(
    [Parameter()]
    [System.String]
    $ModuleRootPath = ($PSScriptRoot | Split-Path -Parent)
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
    $script:guid =  (New-Guid).ToString().Substring(0,8)
    $script:guid = '5889b15h'
    $script:DataFactoryName = "SQLPlayerDemo-$Stage-$guid"
    $script:SrcFolder = $env:ADF_ExampleCode
    $script:Location = "NorthEurope"
    $script:AllExcluded = (New-AdfPublishOption)
    $script:AllExcluded.Excludes.Add('*','')
    $script:AllExcluded.StopStartTriggers = $false
    $script:AllExcluded.DeleteNotInSource = $false
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)

    Remove-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName" -Force
    Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "###" -Recurse:$true -Force 

    Describe 'Publish-AdfV2FromJson' -Tag 'Integration' {
        # It 'Folder should exist' {
        #     { Get-Command -Name Import-AdfFromFolder -ErrorAction Stop } | Should -Not -Throw
        # }

        Context 'when does not exist and called without Location' {
            It 'Throw error' {
                { Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" } | Should -Throw
            }
        }

        Context 'when does not exist and called with option CreateNewInstance=false' {
            It 'Throw error' {
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
                $PipelineName = "PL_Wait"
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


        





        Context 'ADF exist and publish whole ADF' {
            It 'Should finish successfully' {
                Copy-Item -path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.json" -Recurse:$true -Force 
                Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                    -ResourceGroupName "$ResourceGroupName" `
                    -DataFactoryName "$DataFactoryName" -Location "$Location" 
            }
            It 'Should contains the same number of objects as files' {
                $filesCount = (Get-ChildItem -Path "$TmpFolder" -Filter "*.json" -Recurse:$true | Measure-Object).Count
                $adfIns = Get-AdfFromService -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
                $adfIns.AllObjects().Count | Should Be $filesCount
            }
        }


    } 
}
