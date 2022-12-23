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
    $t = Get-TargetEnv 'adf1'
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
    $adf.PublishOptions = $o
    Publish-AdfV2FromJson -RootFolder $RootFolder -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -Option $o -Location $Location
    $script:adfIns = Get-AdfFromService -FactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName


    Describe 'Remove-AdfObject' {
        It 'Should exist' {
            { Get-Command -Name 'Remove-AdfObject' -ErrorAction Stop } | Should -Not -Throw
        }


        Context 'When called for dep object but it is excluded' {
            It 'Should not delete any object' {
                $objCountBefore = $adfIns.AllObjects().Count
                $objToDelete = $script:adfIns.LinkedServices[0]
                $script:adf.PublishOptions.Includes.Add('*.*2','')
                Remove-AdfObject -adfSource $script:adf -obj $objToDelete -adfInstance $script:adfIns
                $adfIns = Get-AdfFromService -FactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
                $objCountAfter = $adfIns.AllObjects().Count
                $objCountAfter | Should -Be $objCountBefore
            }
        }

        Context 'When called for dep object' {
            It 'Should delete all dependant objects when option DoNotDeleteExcludedObj = false' {
                $objCountBefore = $adfIns.AllObjects().Count
                $objToDelete = $script:adfIns.LinkedServices[0]
                $opt = New-AdfPublishOption
                $opt.StopStartTriggers = $false
                $opt.DoNotDeleteExcludedObjects = $false
                $opt.Includes.Add('*.*2','')
                $script:adf.PublishOptions = $opt
                { Remove-AdfObject -adfSource $script:adf -obj $objToDelete -adfInstance $script:adfIns -ErrorAction Stop } | Should -Not -Throw
                #Remove-AdfObject -adfSource $script:adf -obj $objToDelete -adfInstance $script:adfIns
                $adfIns = Get-AdfFromService -FactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
                $objCountAfter = $adfIns.AllObjects().Count
                $objCountAfter | Should -Be 0
            }
        }



    } 
}
