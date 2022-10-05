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
    $script:ResourceGroupName = 'rg-devops-factory'
    $c = Get-AzContext
    $script:guid = $c.Subscription.Id.Substring(0,8)
    $script:DataFactoryOrigName = 'adf2'
    $script:DataFactoryName = $script:DataFactoryOrigName + "-$guid"
    $script:Location = "UK South"

    Describe 'Publish-AdfV2FromJson' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Publish-AdfV2FromJson -ErrorAction Stop } | Should -Not -Throw
        }
    } 

    Describe 'Publish-AdfV2FromJson' {
        It 'adf2 Should skip deployment of any credential object' {
            $script:RootFolder = "$PSScriptRoot\adf2"
            $o = New-AdfPublishOption
            $o.StopStartTriggers = $false
            $o.Includes.Add("cred*.*", "")
            Publish-AdfV2FromJson -RootFolder $RootFolder -ResourceGroupName $script:ResourceGroupName `
                -Location $script:Location -DataFactoryName $script:DataFactoryName -Option $o
        }

    }

}
