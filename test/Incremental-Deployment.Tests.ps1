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
    $script:adfi = @{}  #Get-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName"
    #$script:RootFolder = Join-Path $PSScriptRoot "BigFactorySample2"
    $script:adf_remote = New-Object -TypeName AdfInstance

    $script:opt = New-AdfPublishOption
    $opt.CreateNewInstance = $false
    $opt.IncrementalDeployment = $true
    $opt.StopStartTriggers = $false
    $script:gp = "" 
    $script:dstate = [AdfDeploymentState]::new('1.0.0')

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
            #Mock Get-AzDataFactoryV2 { return 'ADFInstance' }

            Mock New-AzResource { } # optional
            
            Mock Deploy-AdfObjectOnly -Verifiable -ParameterFilter {$obj.Type -ne 'factory'} {
                $obj = $PesterBoundParameters.obj
                if ($obj.Type -eq "linkedService") {
                    $ls = New-Object 'Microsoft.Azure.Management.DataFactory.Models.LinkedService' 
                    $lsr = New-Object 'Microsoft.Azure.Management.DataFactory.Models.LinkedServiceResource' -ArgumentList $ls, $obj.FullName(), $obj.Name, 'Type'
                    $o = New-Object 'Microsoft.Azure.Commands.DataFactoryV2.Models.PSLinkedService' -ArgumentList $lsr, $obj.Adf.ResourceGroupName, $obj.Adf.Name
                    $adf_remote.LinkedServices.Add($o) | Out-Null
                    $obj.Deployed = $true;
                }
            }

            # Mock Get-GlobalParam { 
            #     $adfi = @{id='/.../ADF/globalParameters/default'; name='default'; type='Microsoft.DataFactory/factories/globalParameters'; properties='' }
            #     $adfi.properties = $script:gp
            #     if (IsPesterDebugMode) {
            #         Write-Host ($adfi | ConvertTo-Json -Depth 10) -BackgroundColor DarkGreen
            #     }
            #     return $adfi
            # }

            # Mock Set-GlobalParam { 
            #     $adf = $PesterBoundParameters.adf
            #     $script:gp = ($adf.GlobalFactory.body | ConvertFrom-Json).properties.globalParameters
            #     if (IsPesterDebugMode) {
            #         Write-Host ($script:gp | ConvertTo-Json -Depth 10) -BackgroundColor DarkRed
            #     }
            # }

            Mock Set-StateToStorage {
                $script:dstate = $PesterBoundParameters.ds
                if (IsPesterDebugMode) {
                    Write-Host ($script:dstate | ConvertTo-Json -Depth 10) -BackgroundColor DarkRed
                }
            }
            Mock Get-StateFromStorage {
            if (IsPesterDebugMode) {
                Write-Host ($script:dstate | ConvertTo-Json -Depth 10) -BackgroundColor DarkGreen
            }
            return $script:dstate
            }

            Mock Remove-AzDataFactoryV2Pipeline {}

            Mock Get-AdfFromService {
                return $adf_remote
            }
        }

        It '"adftools_deployment_state" in GP should be created' {
            Publish-AdfV2FromJson @params
            Should -Invoke -CommandName Set-StateToStorage -Times 1
        }
        It 'New GP "adftools_deployment_state" should exist' {
            Write-Host ($dstate | ConvertTo-Json -Depth 10) -BackgroundColor DarkBlue
            $script:ds1 = $ds
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
            #$ds2 = $gp.adftools_deployment_state.value
            $ds2 = $dstate
            Write-Host ($ds2 | ConvertTo-Json -Depth 5) -BackgroundColor Green
            $ds2.Deployed | Should -Not -BeNullOrEmpty
            $ds2.Deployed.Count | Should -Be 1
            Should -Invoke -CommandName Deploy-AdfObjectOnly -Times 1
        }

        It 'After redeployment: no deployment for untouched object' {
            Write-Host "*** DEPLOY SECOND TIME (OMIT) ***" -BackgroundColor DarkGreen
            Publish-AdfV2FromJson @params
            Should -Invoke -CommandName Deploy-AdfObjectOnly -Times 0
        }


        # Test: Delete & redeploy - object disappears from adftools_deployment_state
        It 'Should remove item from "adftools_deployment_state" when object deleted' {
            Remove-Item -Path "$TmpFolder" -Include "BlobSampleData.json" -Recurse:$true -Force
            $opt.DeleteNotInSource = $true
            Publish-AdfV2FromJson @params
            #$ds3 = $gp.adftools_deployment_state.value
            $ds3 = $dstate
            #$ds3.Deployed.Count | Should -Be 0
            $ds3.Deployed | Should -BeNullOrEmpty
        }

    } 






}
