BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {

    Describe 'Get-SimplifiedType' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Get-SimplifiedType -ErrorAction Stop } | Should -Not -Throw
        }

        $cases= @{ type = 'pipeline'; simtype = 'pipeline'; },
                @{ type = 'PSpipeline'; simtype = 'pipeline';  },
                @{ type = 'AdfPSpipeline'; simtype = 'pipeline'; }

        It 'Should return "<simtype>" when "<type>" provided' -TestCases $cases {
            param ($type, $simtype)
            $expected = $simtype
            $actual = Get-SimplifiedType -Type $type
            $actual | Should -Be $expected
        }

        
    } 
}
