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


    Describe 'Update-GlobalParameters' -Tag 'Unit','private' {

        BeforeAll {
            Mock Set-GlobalParam { }
        }

        It 'Should exist' {
            { Get-Command -Name Update-GlobalParameters -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'When called without parameters' {
            It 'Should throw an error' {
                { Update-GlobalParameters -Force } | Should -Throw 
            }
        }

        $cases= 
        @{ name = 'adf2' },
        @{ name = 'adf3' },
        @{ name = 'BigFactorySample2' }
        Context 'When called with parameters' {
            It 'Should execute Set-GlobalParam command 1 time only if GP exists' -TestCases $cases {
                param ($name)

                $RootFolder = "$PSScriptRoot\$name"
                $script:adf = Import-AdfFromFolder -FactoryName "$name" -RootFolder "$RootFolder"
                $obj = $adf.Factories[0]
                $body = (Get-Content -Path $obj.FileName -Encoding "UTF8" | Out-String)
                $json = $body | ConvertFrom-Json
                $gp_exists = ($name -ne 'adf3')
                $adf.GlobalFactory.GlobalParameters = $json
                $adf.GlobalFactory.body = $body
                Update-GlobalParameters -adf $adf 
                Should -Invoke -CommandName Set-GlobalParam -Times ($gp_exists ? 1 : 0)
            }
        }


        
    }



}
