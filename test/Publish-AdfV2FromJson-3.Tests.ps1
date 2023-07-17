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
    $t = Get-TargetEnv 'adf2'
    $script:ResourceGroupName = $t.ResourceGroupName
    $script:DataFactoryOrigName = $t.DataFactoryOrigName
    $script:DataFactoryName = $t.DataFactoryName
    $script:Location = $t.Location
    $script:SrcFolder = Join-Path $PSScriptRoot $t.DataFactoryOrigName
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path $TmpFolder $t.DataFactoryOrigName

    BeforeAll {
        Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.json" -Recurse:$true -Force 
    }

    Describe 'Publish-AdfV2FromJson' {
        Context 'with IncrementalDeployment and no Factory folder' {
            It 'Should create a folder & file for factory' {
                $factoryPath = Join-Path $RootFolder "factory"
                Remove-Item -Path "$factoryPath" -Recurse
                $o = New-AdfPublishOption
                $o.IncrementalDeployment = $true
                Publish-AdfV2FromJson -RootFolder $RootFolder -ResourceGroupName $script:ResourceGroupName `
                    -Location $script:Location -DataFactoryName $script:DataFactoryOrigName -Option $o -DryRun
            }
        }
    }

    AfterAll {
        Write-Host "Cleaning all filed: $TmpFolder"
        Remove-Item -Path "$TmpFolder" -Recurse
    }

}
