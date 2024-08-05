BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force

    # $VerbosePreference = 'Continue'
    # $DebugPreference = 'Continue'

    # Variables for use in tests
    $script:t = Get-TargetEnv 'BigFactorySample2'
    $script:ResourceGroupName = $t.ResourceGroupName
    $script:DataFactoryOrigName = $t.DataFactoryOrigName
    $script:DataFactoryName = $t.DataFactoryName
    $script:Location = $t.Location
    $script:adfi = @{}
    $script:TargetAdf = $null

    $script:opt = New-AdfPublishOption
    $opt.CreateNewInstance = $true
    $opt.IncrementalDeployment = $true
    $opt.StopStartTriggers = $false
    $script:gp = "" 

    $script:SrcFolder = "$PSScriptRoot\$($script:DataFactoryOrigName)"
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)
    Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "$($t.DataFactoryName).json" -Recurse:$true -Force 

    $script:params = @{ RootFolder = "$RootFolder" 
        ResourceGroupName = "$ResourceGroupName" 
        DataFactoryName = "$DataFactoryName" 
        Location = "$Location" 
        Option = $opt
    }

    Describe 'When deploy ADF in Incremental mode' -Tag 'IncrementalDeployment', 'Unit' {
        BeforeAll {

            Mock Get-AzDataFactoryV2 {
                param ($ResourceGroupName, $Name)
                return $script:TargetAdf
            }
            Mock Set-AzDataFactoryV2 {
                param ($ResourceGroupName, $DataFactoryName, $Location)
                if ($null -eq $script:TargetAdf) {
                    $script:TargetAdf = CreateTargetAdf
                    $script:TargetAdf.Name = $DataFactoryName
                    $script:TargetAdf.ResourceGroupName = $ResourceGroupName
                    $script:TargetAdf.Location = $Location
                }
                return $script:TargetAdf
            }
        
            Mock New-AzResource {
                param ($ResourceType, $ResourceGroupName, $ResourceName, $ApiVersion, $Properties, $IsFullObject)
                $newRes = New-Object -TypeName "AdfObject"
                $newRes.Name = ($ResourceName -split '/')[1]
                $newRes.Type = $ResourceType
                $newRes.Body = $Properties
                $script:TargetAdf.DeployObject($newRes)
            }

            Mock Get-GlobalParam { 
                $adfi = @{id='/.../ADF/globalParameters/default'; name='default'; type='Microsoft.DataFactory/factories/globalParameters'; properties='' }
                $adfi.properties = $script:gp
                if (IsPesterDebugMode) {
                    Write-Host ($adfi | ConvertTo-Json -Depth 10) -BackgroundColor DarkGreen
                }
                return $adfi
            }

            Mock Set-GlobalParam { 
                $adf = $PesterBoundParameters.adf
                $script:gp = ($adf.GlobalFactory.body | ConvertFrom-Json).properties.globalParameters
                if (IsPesterDebugMode) {
                    Write-Host ($script:gp | ConvertTo-Json -Depth 10) -BackgroundColor DarkRed
                }
            }

            Mock Remove-AzDataFactoryV2LinkedService {
                param ($ResourceGroupName, $DataFactoryName, $Name)
                if ($script:TargetAdf) {
                    $script:TargetAdf.RemoveObject("*linkedServices.$Name")
                }
            }
            
            Mock Get-AdfFromService {
                param ($FactoryName, $ResourceGroupName)
                return $script:TargetAdf
            }
        }

        It '"adftools_deployment_state" in GP should be created' {
            Publish-AdfV2FromJson @params
            Should -Invoke -CommandName Set-GlobalParam -Times 1
        }
        It 'New GP "adftools_deployment_state" should exist' {
            Write-Host ($gp | ConvertTo-Json -Depth 10) -BackgroundColor DarkBlue
            $script:ds1 = $gp.adftools_deployment_state.value
        }
        It '"adftools_deployment_state" should contain empty "Deployed"' {
            $ds1.Deployed | Should -BeNullOrEmpty
        }
        It '"adftools_deployment_state" should contain "LastUpdate"' {
            $ds1.LastUpdate | Should -Not -BeNullOrEmpty
        }
        It '"adftools_deployment_state" should contain "adftoolsVer"' {
            $ds1.adftoolsVer | Should -Not -BeNullOrEmpty
        }
        It '"adftools_deployment_state" should contain "Algorithm" = "MD5"' {
            $ds1.Algorithm | Should -BeExactly 'MD5'
        }

        It 'After redeployment of 1 object "adftools_deployment_state" should contain "Deployed" with 1 item' {
            Write-Host "*** DEPLOY FIRST TIME ***" -BackgroundColor DarkGreen
            Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "BlobSampleData.json" -Recurse:$true -Force 
            Publish-AdfV2FromJson @params
            $ds2 = $gp.adftools_deployment_state.value
            Write-Host ($ds2 | ConvertTo-Json -Depth 5) -BackgroundColor Green
            $ds2.Deployed | Should -Not -BeNullOrEmpty
            $ds2.Deployed.Count | Should -Be 1
            Should -Invoke -CommandName New-AzResource -Times 1
        }

        It 'After redeployment: no deployment for untouched object' {
            Write-Host "*** DEPLOY SECOND TIME (OMIT) ***" -BackgroundColor DarkGreen
            Publish-AdfV2FromJson @params
            Should -Invoke -CommandName New-AzResource -Times 0
        }

        # Test: Delete & redeploy - object disappears from adftools_deployment_state
        It 'Should remove item from "adftools_deployment_state" when object deleted' {
            Remove-Item -Path "$TmpFolder" -Include "BlobSampleData.json" -Recurse:$true -Force
            $opt.DeleteNotInSource = $true
            Publish-AdfV2FromJson @params
            $ds3 = $gp.adftools_deployment_state.value
            #$ds3.Deployed.Count | Should -Be 0
            $ds3.Deployed | Should -BeNullOrEmpty
        }

    } 


}
