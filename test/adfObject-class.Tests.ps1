BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force
    Set-Location -Path $PSScriptRoot

    # Variables for use in tests
    #$script:TmpFolder = (New-TemporaryDirectory).FullName
    #Invoke-Expression "explorer.exe '$TmpFolder'"

    Describe 'AdfObject class' -Tag 'class' {
        It 'Should exist' {
            { $script:adf = New-Object -TypeName AdfObject } | Should -Not -Throw
        }

        $cases= @{ FunctionName = 'AddDependant'},
                @{ FunctionName = 'FullName'},
                @{ FunctionName = 'FullNameQuoted'},
                @{ FunctionName = 'IsNameMatch'},
                @{ FunctionName = 'GetFolderName'}
        It 'Should consists "<FunctionName>" function' -TestCases $cases {
            param
            (
                [string] $FunctionName
            )
            $result = (Get-Member -InputObject $adf -Name $FunctionName | Measure-Object).Count 
            $result | Should -Be 1
        }
    } 


    Describe 'GetFolderName function' -Tag 'class' {
        
        Context 'When the object is just created' {
            It 'Should throw' {
                $o = [AdfObject]::new()
                { $o.GetFolderName() } | Should -Throw
            }
        }

        Context 'When the object has been loaded' {
            It 'Should return folder name when defined' {
                $o = New-AdfObjectFromFile -fileRelativePath 'BigFactorySample2\pipeline\PL_Wait_Dynamic.json' -type 'pipeline' -name 'PL_Wait_Dynamic'
                $o.GetFolderName() | Should -Be "ExternalError"
            }
            It 'Should return empty when not defined' {
                $o = New-AdfObjectFromFile -fileRelativePath 'BigFactorySample2\pipeline\PL_Wait5sec.json' -type 'pipeline' -name 'PL_Wait5sec'
                $o.GetFolderName() | Should -Be ''
            }
        }
        
        Context 'When the object has limited nodes in it' {
            It 'Should not throw an error' {
                $o = New-AdfObjectFromFile -fileRelativePath 'BigFactorySample2_vnet\managedVirtualNetwork\default.json' -type 'managedVirtualNetwork' -name 'default'
                $o.Body.Properties.PSObject.Properties.Remove('preventDataExfiltration')
                { $o.GetFolderName() } | Should -Not -Throw
            }
        }

    }

    Describe 'IsNameMatch function' -Tag 'class' {

        It 'Should have type and name after load' {
            $name = 'PL_Wait5sec'
            $type = 'pipeline'
            $o = New-AdfObjectFromFile -fileRelativePath "BigFactorySample2\$type\$name.json" -type $type -name $name
            $o.name | Should -Be $name
            $o.type | Should -Be $type
            $o.FullName($false) | Should -Be "$type.$name"
        }

        Context 'When an object is not in folder' {
            $cases= @{ type = 'pipeline'; name = 'PL_Wait5sec'; pattern = 'PIPEline.*' },
                    @{ type = 'pipeline'; name = 'PL_Wait5sec'; pattern = 'pip*.*' },
                    @{ type = 'pipeline'; name = 'PL_Wait5sec'; pattern = '*.PL_Wait5sec' },
                    @{ type = 'pipeline'; name = 'PL_Wait5sec'; pattern = '*.PL_Wait5sec@' },
                    @{ type = 'pipeline'; name = 'PL_Wait5sec'; pattern = '*.PL_Wait5sec@*' },
                    @{ type = 'pipeline'; name = 'PL_Wait5sec'; pattern = '*.*@' },
                    @{ type = 'pipeline'; name = 'PL_Wait5sec'; pattern = '*.*' }
            It 'Should return True when pattern "<pattern>" matches to object <type>.<name>' -TestCases $cases {
                param (
                    $type, $name, $pattern
                )
                $o = New-AdfObjectFromFile -fileRelativePath "BigFactorySample2\$type\$name.json" -type $type -name $name
                $result = $o.IsNameMatch($pattern)
                $result | Should -Be $true
            }

            $cases= @{ type = 'pipeline'; name = 'PL_Wait5sec'; pattern = 'dataset.*' },
                    @{ type = 'pipeline'; name = 'PL_Wait5sec'; pattern = 'pip*.something*' },
                    @{ type = 'pipeline'; name = 'PL_Wait5sec'; pattern = '*.PL__ait5sec' }
            It 'Should return False when pattern "<pattern>" does not match to object <type>.<name>' -TestCases $cases {
                param (
                    $type, $name, $pattern
                )
                $o = New-AdfObjectFromFile -fileRelativePath "BigFactorySample2\$type\$name.json" -type $type -name $name
                $result = $o.IsNameMatch($pattern)
                $result | Should -Be $false
            }
        }

        Context 'When an object is in folder' {
            $cases= @{ type = 'pipeline'; name = 'PL_Wait_Dynamic'; pattern = 'PIPEline.*' },
                    @{ type = 'pipeline'; name = 'PL_Wait_Dynamic'; pattern = 'pip*.*' },
                    @{ type = 'pipeline'; name = 'PL_Wait_Dynamic'; pattern = '*.PL_Wait_Dynamic' },
                    @{ type = 'pipeline'; name = 'PL_Wait_Dynamic'; pattern = '*.PL_Wait_Dynamic@*' },
                    @{ type = 'pipeline'; name = 'PL_Wait_Dynamic'; pattern = '*.PL_Wait_Dynamic@ExternalError' },
                    @{ type = 'pipeline'; name = 'PL_Wait_Dynamic'; pattern = '*.PL_Wait_Dynamic@*Error' },
                    @{ type = 'pipeline'; name = 'PL_Wait_Dynamic'; pattern = '*.PL_Wait_Dynamic@External*r' },
                    @{ type = 'pipeline'; name = 'PL_Wait_Dynamic'; pattern = '*.*' }
            It 'Should return True when pattern "<pattern>" matches to object <type>.<name>' -TestCases $cases {
                param (
                    $type, $name, $pattern
                )
                $o = New-AdfObjectFromFile -fileRelativePath "BigFactorySample2\$type\$name.json" -type $type -name $name
                $result = $o.IsNameMatch($pattern)
                $result | Should -Be $true
            }
            $cases= @{ type = 'pipeline'; name = 'PL_Wait_Dynamic'; pattern = 'dataset.*' },
                    @{ type = 'pipeline'; name = 'PL_Wait_Dynamic'; pattern = 'pip*.something*' },
                    @{ type = 'pipeline'; name = 'PL_Wait_Dynamic'; pattern = '*.PL_Wait_Dynamic@' }
            It 'Should return False when pattern "<pattern>" does not match to object <type>.<name>' -TestCases $cases {
                param (
                    $type, $name, $pattern
                )
                $o = New-AdfObjectFromFile -fileRelativePath "BigFactorySample2\$type\$name.json" -type $type -name $name
                $result = $o.IsNameMatch($pattern)
                $result | Should -Be $false
            }

        }

    }

}


