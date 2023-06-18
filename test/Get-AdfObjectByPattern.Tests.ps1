BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {

    # Variables for use in tests
    $script:SrcFolder = Join-Path $PSScriptRoot "BigFactorySample2"

    Describe 'Get-AdfObjectByPattern' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Get-AdfObjectByPattern -ErrorAction Stop } | Should -Not -Throw
        }

    }

    Describe 'Get-AdfObjectByPattern' {

        $script:adf = Import-AdfFromFolder -FactoryName 'BF2' -RootFolder $SrcFolder
        [System.Collections.ArrayList] $cases = @{}
        foreach ($t in [AdfObject]::AllowedTypes) {
            $cases.Add( @{ type = $t } )
        }
        
        It 'Should execute function successfully for type "<type>"' -TestCases $cases {
            $res = Get-AdfObjectByPattern -adf $adf -name '*' -type $type
            $arr = $res | ToArray
            $arr.Length | Should -BeGreaterOrEqual 0
        }

    }

}
