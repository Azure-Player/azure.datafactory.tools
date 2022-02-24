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

    Describe 'of BigFactorySample2_vnet without properties node and exclude rules' {
        BeforeEach {
            $DataFactoryName = "BigFactorySample2_vnet"
            $RootFolder = Join-Path -Path $PSScriptRoot -ChildPath $DataFactoryName
            $vnetFile = Join-Path $RootFolder 'managedVirtualNetwork\default.json'
            $bf = Backup-File -FileName $vnetFile
        }

        It 'Should completed successfully' {
            Remove-ObjectPropertyFromFile -FileName $vnetFile -Path 'properties'
            $adf = Import-AdfFromFolder -FactoryName $DataFactoryName -RootFolder $RootFolder
            $option = [AdfPublishOption]::new()
            $option.Excludes.Add('managedVirtualNetwork*.*', '')
            $adf.PublishOptions = $option
            { ApplyExclusionOptions -adf $adf } | Should -Not -Throw
            #$bf
        }

        AfterEach {
            if ($bf) {
                Write-Verbose "Restoring file from backup: $bf"
                Restore-File -FileName $bf -RemoveBackup $true 
            }
        }
        
    }

}
