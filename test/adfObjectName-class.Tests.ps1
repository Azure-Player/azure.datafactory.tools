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
    #$script:TmpFolder = (New-TemporaryDirectory).FullName
    #Invoke-Expression "explorer.exe '$TmpFolder'"

    Describe 'AdfObjectName class' -Tag 'class' {
        It 'Should throw error when type is unknown' {
            { $script:obj = New-Object -TypeName AdfObjectName 'name', 'type' } | Should -Throw
        }
        It 'Should exist' {
            { $script:obj = New-Object -TypeName AdfObjectName 'name', 'dataset' } | Should -Not -Throw
        }
        It 'Should fails when no params passed' {
            { New-Object -TypeName AdfObjectName } | Should -Throw
        }
        It 'Should not fails when one 2-part name as param passed' {
            { New-Object -TypeName AdfObjectName 'trigger.name123' } | Should -Not -Throw
        }
        It 'Should not fails when one 3-part name as param passed' {
            { New-Object -TypeName AdfObjectName 'trigger.name_123@folder' } | Should -Not -Throw
        }
        It 'Should fails when wrong params passed' {
            { New-Object -TypeName AdfObjectName 'unknownType.name123' } | Should -Throw
        }

        $cases= 
                @{ FunctionName = 'FullName'},
                @{ FunctionName = 'FullNameQuoted'},
                @{ FunctionName = 'IsNameMatch'}
                @{ FunctionName = 'IsNameExcluded'}
        It 'Should consists "<FunctionName>" function' -TestCases $cases {
            param
            (
                [string] $FunctionName
            )
            $result = (Get-Member -InputObject $obj -Name $FunctionName | Measure-Object).Count 
            $result | Should -Be 1
        }
    } 


    Describe 'ctor' -Tag 'class' {
        It 'Should have type, name and folder after load' {
            $name = 'PL_Wait Dyna-mic'
            $type = 'pipeline'
            $folder = 'External @ Error'
            $o = [AdfObjectName]::new($name, $type, $folder)
            $o.name | Should -Be $name
            $o.type | Should -Be $type
            $o.folder | Should -Be $folder
            $o.FullNameWithFolder() | Should -Be "$type.$name@$folder"
            $o = [AdfObjectName]::new("$type.$name@$folder")
            $o.name | Should -Be $name
            $o.type | Should -Be $type
            $o.folder | Should -Be $folder
        }
    }

    Describe 'IsNameExcluded' -Tag 'class' {

        $cases= 
        @{ pattern = 'pip*.*@*'; expected = $true},
        @{ pattern = '*.*@fold'; expected = $false},
        @{ pattern = 'tri*.*@*'; expected = $false},
        @{ pattern = '*.*'; expected = $true},
        @{ pattern = 'pipeline.PL_Wait_Dynamic'; expected = $false},
        @{ pattern = 'pipeline.PL_Wait_Dynamic@*'; expected = $true},
        @{ pattern = 'pipeline.PL_Wait_Dynamic@ExternalError'; expected = $true},
        @{ pattern = 'pipeline.PL_*@ExternalError'; expected = $true},
        @{ pattern = 'pipeline.PL_Wait_Dynamic@ExternalError'; expected = $true},
        @{ pattern = 'pipeline.PL_*@'; expected = $false},
        @{ pattern = '<NULL>'; expected = $false},
        @{ pattern = ''; expected = $false}

        It 'Should return <expected> when name match to pattern (<pattern>) in Excludes collection' -TestCases $cases {
            param
            (
                [string] $pattern,
                [boolean] $expected
            )
            $name = 'PL_Wait_Dynamic'
            $type = 'pipeline'
            $folder = 'ExternalError'
            $o = [AdfObjectName]::new($name, $type, $folder)
            $opt = New-AdfPublishOption
            if ('<NULL>' -ne $pattern) {
                $opt.Excludes.Add($pattern,'')
            }
            $o.IsNameExcluded($opt) | Should -Be $expected

            # $opt = New-AdfPublishOption
            # $opt.Includes.Add($pattern,'')
            # $o.IsNameExcluded($opt) | Should -Not -Be $expected

        }
    }
    
    Describe 'IsNameExcluded' -Tag 'class' {

        $cases= 
        @{ pattern = 'pip*.*@*'; expected = $false},
        @{ pattern = 'tri*.*@*'; expected = $true},
        @{ pattern = '*.*'; expected = $false},
        @{ pattern = '<NULL>'; expected = $false},
        @{ pattern = ''; expected = $true}

        It 'Should return <expected> when name match to pattern (<pattern>) in Includes collection' -TestCases $cases {
            param
            (
                [string] $pattern,
                [boolean] $expected
            )
            $name = 'PL_Wait_Dynamic'
            $type = 'pipeline'
            $folder = 'ExternalError'
            $o = [AdfObjectName]::new($name, $type, $folder)
            $opt = New-AdfPublishOption
            if ('<NULL>' -ne $pattern) {
                $opt.Includes.Add($pattern,'')
            }
            $o.IsNameExcluded($opt) | Should -Be $expected

        }
    }

}


