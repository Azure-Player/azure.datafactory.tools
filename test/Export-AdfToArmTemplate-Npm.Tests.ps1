BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {

    # Issue #462: on Windows, 'npm' runs npm.ps1, which fails on Windows PowerShell 5.1
    Describe 'Get-AdfNpmCommand' -Tag 'Unit' {

        BeforeAll {
            $script:origOS = $env:OS
        }

        AfterEach {
            $env:OS = $script:origOS
        }

        It 'Should return npm.cmd on Windows' {
            $env:OS = 'Windows_NT'
            Get-AdfNpmCommand | Should -Be 'npm.cmd'
        }

        It 'Should return npm on other systems' {
            $env:OS = $null
            Get-AdfNpmCommand | Should -Be 'npm'
        }
    }

    Describe 'Invoke-AdfNpm' -Tag 'Unit' {

        BeforeAll {
            function Invoke-FakeNpm { $global:LASTEXITCODE = $script:fakeExitCode; $script:fakeArgs = $args }
        }

        BeforeEach {
            $ErrorActionPreference = 'Continue'
            $script:fakeExitCode = 0
            $script:fakeArgs = $null
            Mock Get-AdfNpmCommand { 'Invoke-FakeNpm' }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should pass the arguments to npm' {
            Invoke-AdfNpm -Arguments 'i', '@microsoft/azure-data-factory-utilities'
            $script:fakeArgs | Should -Be @('i', '@microsoft/azure-data-factory-utilities')
        }

        It 'Should throw when npm fails' {
            $script:fakeExitCode = 1
            { Invoke-AdfNpm -Arguments 'i', 'pkg' } | Should -Throw "*'npm i pkg' failed with exit code 1*"
        }
    }

    Describe 'Export-AdfToArmTemplate calls npm' -Tag 'Unit' {

        BeforeAll {
            $script:origLocation = Get-Location
        }

        BeforeEach {
            $ErrorActionPreference = 'Continue'
            $script:RootFolder = Join-Path $TestDrive 'adf1'
            New-Item -Path $script:RootFolder -ItemType Directory -Force | Out-Null
            Mock Invoke-AdfNpm { }
        }

        AfterEach {
            Set-Location $script:origLocation
        }

        It 'Should check the version, install the utilities and export' {
            Export-AdfToArmTemplate -RootFolder $script:RootFolder -SubscriptionId 'sub1' -ResourceGroup 'rg1' -OutputFolder 'out'
            Should -Invoke Invoke-AdfNpm -Times 3 -Exactly
            Should -Invoke Invoke-AdfNpm -Times 1 -Exactly -ParameterFilter { ($Arguments -join ' ') -eq 'version' }
            Should -Invoke Invoke-AdfNpm -Times 1 -Exactly -ParameterFilter { ($Arguments -join ' ') -eq 'i @microsoft/azure-data-factory-utilities' }
            Should -Invoke Invoke-AdfNpm -Times 1 -Exactly -ParameterFilter {
                ($Arguments -join ' ') -eq "run build export $($script:RootFolder) /subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.DataFactory/factories/adf1 out"
            }
        }

        It 'Should stop when npm install fails' {
            Mock Invoke-AdfNpm { throw 'npm failed' } -ParameterFilter { $Arguments[0] -eq 'i' }
            { Export-AdfToArmTemplate -RootFolder $script:RootFolder } | Should -Throw 'npm failed'
            Should -Invoke Invoke-AdfNpm -Times 0 -Exactly -ParameterFilter { $Arguments[0] -eq 'run' }
        }
    }
}
