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

    Describe 'Test-AdfCode' -Tag 'Unit' {
        It 'Should run successfully even for empty factory' {
            $DataFactoryName = "emptyFactory"
            $RootFolder = Join-Path -Path $PSScriptRoot -ChildPath $DataFactoryName
            { Test-AdfCode $RootFolder } | Should -Not -Throw
        }

    } 


    Describe 'Test-AdfCode' -Tag 'Unit' {
        It 'Should not throw error due to missing file' {
            $DataFactoryName = "BigFactorySample2_vnet"
            $RootFolder = Join-Path -Path $PSScriptRoot -ChildPath $DataFactoryName
            { 
                $script:res = Test-AdfCode -RootFolder $RootFolder
            } | Should -Not -Throw
        }
        It 'Should return 1 error and 6 warnings in ReturnClass' {
            $script:res.GetType() | Should -Be 'Test-AdfCode.ReturnClass'
            $script:res.ErrorCount | Should -Be 1
            $script:res.WarningCount | Should -Be 6
        }
    }


    Describe 'Test-AdfCode' -Tag 'Unit' {
        It 'Should not throw error when factory has no GP but other global config' {
            $DataFactoryName = "adf3"
            $RootFolder = Join-Path -Path $PSScriptRoot -ChildPath $DataFactoryName
            { 
                $script:res = Test-AdfCode -RootFolder $RootFolder
            } | Should -Not -Throw
        }
    }

    Describe 'Test-AdfCode' -Tag 'Unit' {
        It 'Should parse properly adf2 code' {
            $DataFactoryName = "adf2"
            $RootFolder = Join-Path -Path $PSScriptRoot -ChildPath $DataFactoryName
            { 
                $script:res = Test-AdfCode -RootFolder $RootFolder
            } | Should -Not -Throw
        }
    }


    Describe 'Test-AdfCode' -Tag 'Unit' {
        It 'Should throw an error when wrong path to DF is provided' {
            $DataFactoryName = "nullPathFactory"
            $RootFolder = Join-Path -Path $PSScriptRoot -ChildPath $DataFactoryName
            { 
                $script:res = Test-AdfCode -RootFolder $RootFolder -ConfigPath $null
            } | Should -Throw
        }
        It 'Should not throw an error when correct path to DF is provided but ConfigPath is null' {
            $DataFactoryName = "adf2"
            $RootFolder = Join-Path -Path $PSScriptRoot -ChildPath $DataFactoryName
            { 
                $script:res = Test-AdfCode -RootFolder $RootFolder -ConfigPath $null
            } | Should -Not -Throw
        }
    }

    Describe 'Test-AdfCode trigger without pipeline references #507' -Tag 'Unit' {
        BeforeEach {
            Mock Write-Warning {}
        }

        It 'Should warn about enabled trigger TR_without_pipeline in adf2' {
            $RootFolder = Join-Path -Path $PSScriptRoot -ChildPath 'adf2'
            $script:res = Test-AdfCode -RootFolder $RootFolder
            Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like '*TR_without_pipeline*' }
        }

        It 'Should return 0 errors and 1 warning for adf2' {
            $script:res.ErrorCount | Should -Be 0
            $script:res.WarningCount | Should -Be 1
        }

        It 'Should <expected> for <type> with runtimeState <state> (<case>)' -ForEach @(
            @{ case = 'empty pipelines';       type = 'ScheduleTrigger';       state = 'Started'; prop = 'pipelines'; refs = $false; expected = 'warn' }
            @{ case = 'no pipelines property'; type = 'ScheduleTrigger';       state = 'Started'; prop = $null;       refs = $false; expected = 'warn' }
            @{ case = 'empty pipelines';       type = 'BlobEventsTrigger';     state = 'Started'; prop = 'pipelines'; refs = $false; expected = 'warn' }
            @{ case = 'no pipeline property';  type = 'TumblingWindowTrigger'; state = 'Started'; prop = $null;       refs = $false; expected = 'warn' }
            @{ case = 'with pipeline';         type = 'ScheduleTrigger';       state = 'Started'; prop = 'pipelines'; refs = $true;  expected = 'not warn' }
            @{ case = 'with pipeline';         type = 'TumblingWindowTrigger'; state = 'Started'; prop = 'pipeline';  refs = $true;  expected = 'not warn' }
            @{ case = 'empty pipelines';       type = 'ScheduleTrigger';       state = 'Stopped'; prop = 'pipelines'; refs = $false; expected = 'not warn' }
            @{ case = 'no pipeline property';  type = 'TumblingWindowTrigger'; state = 'Stopped'; prop = $null;       refs = $false; expected = 'not warn' }
        ) {
            $RootFolder = Join-Path -Path $TestDrive -ChildPath "adf435-$([guid]::NewGuid().ToString('N').Substring(0,8))"
            New-Item -ItemType Directory -Path "$RootFolder/trigger", "$RootFolder/pipeline" -Force | Out-Null
            '{ "name": "PL_Wait", "properties": { "activities": [] } }' | Set-Content "$RootFolder/pipeline/PL_Wait.json"

            $pipelineRef = @{ pipelineReference = @{ referenceName = 'PL_Wait'; type = 'PipelineReference' } }
            $properties = [ordered]@{ runtimeState = $state; type = $type; typeProperties = @{} }
            switch ($prop) {
                'pipelines' { $properties.pipelines = if ($refs) { @($pipelineRef) } else { @() } }
                'pipeline'  { $properties.pipeline = $pipelineRef }
            }
            @{ name = 'TR_Test'; properties = $properties } | ConvertTo-Json -Depth 10 | Set-Content "$RootFolder/trigger/TR_Test.json"

            Test-AdfCode -RootFolder $RootFolder | Out-Null

            $times = if ($expected -eq 'warn') { 1 } else { 0 }
            Should -Invoke Write-Warning -Times $times -Exactly -ParameterFilter { $Message -like '*TR_Test*' }
        }
    }

    Describe 'Test-AdfCode' -Tag 'Unit' {
        It 'Should not throw an error when Get-ChildItem Path parameter is null' {
            $DataFactoryName = "adf2"
            $RootFolder = Join-Path -Path $PSScriptRoot -ChildPath $DataFactoryName
            
            # Mock Get-ChildItem cmdlet to raise an error when Path parameter is null
            Mock Get-ChildItem {
                param($Path)
                throw 'Cannot process argument because the value of argument "path" is not valid. Change the value of the "path" argument and run the operation again.'
            } -ParameterFilter {$Path -eq $null}
            # Pester 6 no longer falls through to the real command when no filter matches
            Mock Get-ChildItem { & (Get-Command Get-ChildItem -CommandType Cmdlet) @PesterBoundParameters }
            
            { 
                $script:res = Test-AdfCode -RootFolder $RootFolder -ConfigPath $null
            } | Should -Not -Throw
        }
    }

}
