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
    $script:DataFactoryOrigName = $t.DataFactoryOrigName
    $script:DataFactoryName = $t.DataFactoryName
    $script:Location = $t.Location
    $script:ResourceGroupName = $t.ResourceGroupName
    $script:Stage = 'UAT'
    $script:RootFolder = Join-Path $PSScriptRoot $t.DataFactoryOrigName
    $script:adf = Import-AdfFromFolder -FactoryName $script:DataFactoryName -RootFolder $script:RootFolder
    $adf.ResourceGroupName = $t.ResourceGroupName
    $adf.Region = $t.Location
    $o = New-AdfPublishOption
    $o.StopStartTriggers = $false
    $o.Includes.Add('cred*.*','')
    $adf.PublishOptions = $o
    Publish-AdfV2FromJson -RootFolder $RootFolder -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -Option $o -Location $Location
    $script:adfIns = Get-AdfFromService -FactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName


    Describe 'Remove-AdfObjectRestAPI' {
        It 'Should exist' {
            { Get-Command -Name 'Remove-AdfObjectRestAPI' -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'When called Remove-AdfObjectRestAPI' {
            It 'Should delete the existing credential object' {
                $objCountBefore = $adfIns.AllObjects().Count
                Remove-AdfObjectRestAPI -type_plural 'credentials' -name 'credential1' -adfInstance $script:adfIns
                $adfIns = Get-AdfFromService -FactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
                $objCountAfter = $adfIns.AllObjects().Count
                $objCountAfter | Should -Be ($objCountBefore-1)
            }
        }


    } 
}
