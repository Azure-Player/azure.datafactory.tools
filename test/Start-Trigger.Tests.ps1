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
    $script:SrcFolder = "$PSScriptRoot\BigFactorySample2"
    $script:DataFactoryName = (Split-Path -Path $script:SrcFolder -Leaf) + "-$guid"
    $script:Location = "NorthEurope"
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)

    Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "###" -Recurse:$true -Force 
    #Invoke-Expression "explorer.exe '$TmpFolder'"


    Describe 'Command ' -Tag 'Unit' {
        It 'Start-Triggers Should exist' {
            { Get-Command -Name Start-Triggers -ErrorAction Stop } | Should -Not -Throw
        }
        It 'Start-Trigger Should exist' {
            { Get-Command -Name Start-Trigger -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Describe 'Start-Trigger' -Tag 'Unit' {

        It 'Should retry after the first failure' {
            $script:attempts = 2
            Mock Start-AzDataFactoryV2Trigger { $attempts--; if ($attempts -eq 0) { Write-Host 'OK' } else { Write-Error 'BadRequest' } }
            Start-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1' 
            Assert-MockCalled Start-AzDataFactoryV2Trigger -Times 2
        }

        It 'Should retry max 5 times when failure' {
            Mock Start-AzDataFactoryV2Trigger { Write-Error 'BadRequest' }
            Start-Trigger -ResourceGroupName 'rg' -DataFactoryName 'adf' -Name 'tr1' 
            Assert-MockCalled Start-AzDataFactoryV2Trigger -Times 5
        }

    } 
}




# https://pester.dev/docs/usage/mocking

