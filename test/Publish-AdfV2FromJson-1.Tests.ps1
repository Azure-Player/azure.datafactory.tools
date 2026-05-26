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

    Describe 'Publish-AdfV2FromJson' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Publish-AdfV2FromJson -ErrorAction Stop } | Should -Not -Throw
        }
    } 

    Describe 'Publish-AdfV2FromJson' {
        It 'adf2 Should skip referenced Synapse notebook in a pipeline' {
            $script:RootFolder = Join-Path $PSScriptRoot "adf2"
            $o = New-AdfPublishOption
            $o.StopStartTriggers = $false
            $o.Includes.Add("pipe*.*", "")
            $o.Includes.Add("*.LS_AzureSynapseArtifacts1", "")
            Publish-AdfV2FromJson -RootFolder $RootFolder -ResourceGroupName $script:ResourceGroupName `
                -Location $script:Location -DataFactoryName $script:DataFactoryName -Option $o
        }

        It 'adf2 Should deploy credential1 to ADF service' {
            $script:RootFolder = Join-Path $PSScriptRoot "adf2"
            $o = New-AdfPublishOption
            $o.StopStartTriggers = $false
            $o.Includes.Add("credential.credential1", "")
            Publish-AdfV2FromJson -RootFolder $script:RootFolder -ResourceGroupName $script:ResourceGroupName `
                -Location $script:Location -DataFactoryName $script:DataFactoryName -Option $o
            $adfIns = Get-AdfFromService -FactoryName $script:DataFactoryName -ResourceGroupName $script:ResourceGroupName
            $adfIns.Credentials | Where-Object { $_.Name -eq 'credential1' } | Should -Not -BeNullOrEmpty
        }

    }

}
