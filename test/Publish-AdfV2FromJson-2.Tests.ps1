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
    $t = Get-TargetEnv 'BigFactorySample2'
    $script:ResourceGroupName = $t.ResourceGroupName
    $script:DataFactoryOrigName = $t.DataFactoryOrigName
    $script:DataFactoryName = $t.DataFactoryName
    $script:Location = $t.Location
    $script:adfi = Get-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName"


    Describe 'Get-AzDFV2Credential' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Get-AzDFV2Credential -ErrorAction Stop } | Should -Not -Throw
        }
        It 'Should run successfully' {
            { Get-AzDFV2Credential -adfi $adfi | ToArray } | Should -Not -Throw
        }
    } 

    Describe 'Publish-AdfV2FromJson' {
        It 'BigFactorySample2 should deploy credential object successfully' {
            $script:RootFolder = Join-Path $PSScriptRoot "BigFactorySample2"
            $o = New-AdfPublishOption
            $o.StopStartTriggers = $false
            $o.Includes.Add("cred*.*", "")
            $o.Includes.Add("linked*.ls_azurekeyvault", "")
            Publish-AdfV2FromJson -RootFolder $RootFolder -ResourceGroupName $script:ResourceGroupName `
                -Location $script:Location -DataFactoryName $script:DataFactoryName -Option $o
        }
        It 'must return credential object after deployment' {
            $crs = Get-AzDFV2Credential -adfi $adfi | ToArray
            $crs.Count | Should -Be 1
        }
    }



}
