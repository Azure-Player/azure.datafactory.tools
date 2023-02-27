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


    Describe 'Find-RefObject' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Find-RefObject -ErrorAction Stop } | Should -Not -Throw
        }
        It 'Should run' {
            [System.Collections.ArrayList] $arr = [System.Collections.ArrayList]::new()
            $script:ind = 0
            $node = '{ }' | ConvertFrom-Json
            Find-RefObject -node $node -list $arr
        }
    }

    Describe 'Get-ReferencedObjects' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Get-ReferencedObjects -ErrorAction Stop } | Should -Not -Throw
        }

        # Temporarly disabled as it returns different exception type depends on running environment
        # It 'Should return ArgumentNullException when no input param passes' {
        #     { Get-ReferencedObjects } | Should -Throw -ExceptionType 'System.ArgumentNullException'        # Return on local PC
        #     { Get-ReferencedObjects } | Should -Throw -ExceptionType 'System.Management.Automation.ParameterBindingException'   # Return on Agent DevOps
        # }

        $cases= @{ Adf = 'BigFactorySample2'; Name = 'dataset\CADOutput1'; RefCount = 1},
                @{ Adf = 'BigFactorySample2'; Name = 'dataset\CurrencyDatasetCAD'; RefCount = 1},
                @{ Adf = 'BigFactorySample2'; Name = 'linkedService\LS_AzureKeyVault'; RefCount = 0},
                @{ Adf = 'BigFactorySample2'; Name = 'pipeline\TaxiDemo'; RefCount = 1},
                @{ Adf = 'BigFactorySample2'; Name = 'dataflow\Currency Converter'; RefCount = 4},
                @{ Adf = 'adf2';              Name = 'dataset\DS_Json'; RefCount = 1},
                @{ Adf = 'adf2';              Name = 'pipeline\SynapseNotebook1'; RefCount = 3}

        It 'Should find <RefCount> refs in object "<Adf>\<Name>"' -TestCases $cases {
            param
            (
                [string] $Adf,
                [string] $Name,
                [string] $RefCount
            )
            $script:RootFolder = "$PSScriptRoot\$Adf"
            $o = Get-AdfObjectFromFile -FullPath "$($RootFolder)\$Name.json"
            $o | Should -Not -Be $null
            $refs = Get-ReferencedObjects -obj $o
            @($refs).Count | Should -Be $RefCount
        }

        $cases= 
                @{ Adf = 'adf2';              Name = 'dataset\DS_Json' },
                @{ Adf = 'adf2';              Name = 'pipeline\SynapseNotebook1' }

        It 'Should find refs in object "<Adf>\<Name>" with expression' -TestCases $cases {
            param
            (
                [string] $Adf,
                [string] $Name
            )
            $script:RootFolder = "$PSScriptRoot\$Adf"
            $o = Get-AdfObjectFromFile -FullPath "$($RootFolder)\$Name.json"
            $o | Should -Not -Be $null
            $refs = Get-ReferencedObjects -obj $o
            foreach ($r in $refs) {
                [AdfObjectName]::new($r)
            }
            
        }

    } 
}
