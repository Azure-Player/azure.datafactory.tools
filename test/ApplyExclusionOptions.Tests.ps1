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
    $script:DataFactoryName = "BigFactorySample2"
    $script:RootFolder = Join-Path -Path $PSScriptRoot -ChildPath $DataFactoryName

    Describe 'ApplyExclusionOptions' -Tag 'class' {

        It 'Should mark only objects in a given folder' {
            $adf = Import-AdfFromFolder -FactoryName $script:DataFactoryName -RootFolder $script:RootFolder
            $opt = [AdfPublishOption]::new()
            $opt.Includes.Add("*.*@External*", "")
            $adf.PublishOptions = $opt
            ApplyExclusionOptions -adf $adf
            $marked_arr = $adf.AllObjects() | Where-Object { $_.ToBeDeployed -eq $true }
            $marked_arr.Count | Should -Be 2
        }

    } 
}
