BeforeDiscovery {
    $ModuleRootPath = (Get-Location)
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {
    $script:SrcFolder = $env:ADF_ExampleCode
    $script:ConfigFolder = Join-Path -Path $script:SrcFolder -ChildPath "deployment"

    . ".\test\New-TempDirectory.ps1"

    # Variables for use in tests
    #$script:SrcFolder = $env:ADF_ExampleCode
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)
    $script:DeploymentFolder = Join-Path -Path $script:RootFolder -ChildPath "deployment"

    Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.*" -Recurse:$true -Force

    Describe 'Read-JsonConfigFile' -Tag 'Unit','private' {
        It 'Should exist' {
            { Get-Command -Name Read-JsonConfigFile -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'When called without parameters' {
            It 'Should throw an error' {
                { Read-JsonConfigFile -Force } | Should -Throw
            }
        }

        Context 'When called with FailsWhenConfigItemNotFound = $true' {
            It 'Should not throw when object exists' {
                {
                    $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                    $script:option = New-AdfPublishOption
                    $option.FailsWhenConfigItemNotFound = $true
                    Read-JsonConfigFile -Path ( Join-Path -Path $script:ConfigFolder -ChildPath "config-c100.json" ) -Adf $adf -Option $option -ErrorAction Stop
                } | Should -Not -Throw
            }
             It 'Should throw when object is missing' {
                {
                    $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                    $script:option = New-AdfPublishOption
                    $option.FailsWhenConfigItemNotFound = $true
                    Read-JsonConfigFile -Path ( Join-Path -Path $script:ConfigFolder -ChildPath "config-missing.json" ) -Adf $adf -Option $option -ErrorAction Stop
                } | Should -Throw
             }
        }

        Context 'When called with FailsWhenConfigItemNotFound = $false' {
            It 'Should not throw when object exists' {
                {
                    $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                    $script:option = New-AdfPublishOption
                    $option.FailsWhenConfigItemNotFound = $false
                    Read-JsonConfigFile -Path ( Join-Path -Path $script:ConfigFolder -ChildPath "config-c100.json" ) -Adf $adf -Option $option -ErrorAction Stop
                } | Should -Not -Throw
            }
             It 'Should not throw when object is missing' {
                {
                    $script:adf = Import-AdfFromFolder -FactoryName "xyz" -RootFolder "$RootFolder"
                    $script:option = New-AdfPublishOption
                    $option.FailsWhenConfigItemNotFound = $false
                    Read-JsonConfigFile -Path ( Join-Path -Path $script:ConfigFolder -ChildPath "config-missing.json" ) -Adf $adf -Option $option -ErrorAction Stop
                } | Should -Not -Throw
             }
        }
    }
}
