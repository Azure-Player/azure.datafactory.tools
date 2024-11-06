BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
    $m = Get-Module -Name 'azure.datafactory.tools'
    $script:verStr = $m.Version.ToString(2) + "." + $m.Version.Build.ToString("000");
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
    $script:dstate = [AdfDeploymentState]::new($verStr)
    $script:dstate.LastUpdate = [System.DateTime]::UtcNow
    $script:dstateJson = $script:dstate | ConvertTo-Json
    $script:StorageUri= "https://sqlplayer2020.blob.core.windows.net"
    $StorageContainer = "adftools"
    $StorageFolder    = "folder2"
    $script:uri = "$StorageUri/$StorageContainer/$StorageFolder"
    # https://sqlplayer2020.file.core.windows.net/adftools

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

    Describe 'IO operations on file with UTF8' {

        It 'Test temp path' {
            Test-Path -Path (Get-Location) | Should -Be $True
        }
        
        It 'Save UTF8 without BOM' {
            $Body = 'abc Nowiński'; 
            $filePath = '~$testutf8.txt'
            $fullPath = Save-ContentUTF8 -Path $filePath -Value $Body

            $isExist = Test-Path $filePath
            $isExist | Should -Be $true
            Write-Host "Tested file location: $filePath  (result: $isExist)"
            Write-Host "Current location: $(Get-Location)"

            $fileBytes = [System.IO.File]::ReadAllBytes($fullPath)
            ($fileBytes | ForEach-Object { "{0:X2}" -f $_ }) -join " "
            $eolLength = 1; if ($IsWindows) { $eolLength = 2 }
            $fileBytes.Length | Should -Be @(13 + $eolLength)   # Windows - 15, Linux 14 (EOL - 1 or 2 characters)
        }
    }

    Describe 'When Incremental mode with storage provided' -Tag 'IncrementalDeployment', 'Integration' {
        It 'Should return empty state when get for the first time' {
            $script:ds1 = Get-StateFromStorage -DataFactoryName $DataFactoryName -LocationUri "$uri/notexist"
            $ds1.GetType().Name | Should -Be 'AdfDeploymentState'
            $ds1.Deployed | Should -BeNullOrEmpty
        }
        It 'Should save state to storage without an error' {
            $ds1.Deployed.Add("dataflow.DF_UGTurkey", "3A030D67347E840E8C1CC756F14C54FC");
            $ds1.Deployed.Add("linkedService.LS_DataLakeGen1", "825E070ED690D2EA767339EBC6D425A0");
            Set-StateToStorage -ds $ds1 -DataFactoryName $DataFactoryName -LocationUri $uri
        }
        It 'Should return the same value for state when read again' {
            $ds2 = Get-StateFromStorage -DataFactoryName $DataFactoryName -LocationUri $uri
            $ds2.Deployed.Count | Should -Be $script:ds1.Deployed.Count
            #$ds2.adftoolsVer | Should -Be $script:ds1.adftoolsVer
            $ds2.Algorithm | Should -Be $script:ds1.Algorithm
        }
        It 'Should fails when Container doesn''t exist' {
            { Set-StateToStorage -ds $dstate -DataFactoryName $DataFactoryName -LocationUri "$($script:StorageUri)/nocontainer997755/folder" } | Should -Throw
            #-ExceptionType ([System.ArgumentException])
            #| Should -Throw -ExceptionType ([Microsoft.Azure.Storage.StorageException])
            #| Should -Throw -ExceptionType ([System.Management.Automation.PropertyNotFoundException])   #Local PC
        }
        It 'Should save state to storage using UTF8 encoding without BOM' {
            $ds3 = [AdfDeploymentState]::new('9.9')
            $file = Join-Path -Path $PSScriptRoot -ChildPath 'misc\SQLPlayerDemo-UAT.adftools_deployment_state.json'
            $FileContent = Get-Content $file -Encoding 'UTF8'
            $json = $FileContent | ConvertFrom-Json
            $ds3.Deployed = Convert-PSObjectToHashtable $json.Deployed

            $DfName = "$DataFactoryName-withoutBOM"
            $Suffix = "adftools_deployment_state.json"
            Set-StateToStorage -ds $ds3 -DataFactoryName "$DfName" -LocationUri $uri

            # Check saved file directly on Storage
            # $storageAccountName = Get-StorageAccountNameFromUri $uri
            # $storageContext = New-AzStorageContext -UseConnectedAccount -StorageAccountName $storageAccountName
            # $blob = [Microsoft.Azure.Storage.Blob.CloudBlockBlob]::new("$uri/$DfName.$Suffix")
            # $blob.FetchAttributes()
        }
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

        It 'IncrementalDeployment should be ignored when StorageUri is not provided' {
            $script:opt.IncrementalDeploymentStorageUri = ""
            $script:opt.IncrementalDeployment = $true
            Publish-AdfV2FromJson @params
            Should -Invoke -CommandName Set-StateToStorage -Times 0
        }
        It '"adftools_deployment_state" should be created in storage' {
            $script:opt.IncrementalDeploymentStorageUri = $script:uri
            $script:opt.IncrementalDeployment = $true
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

        It 'After redeployment of 2 objects "adftools_deployment_state" should contain "Deployed" with 2 items' {
            Write-Host "*** DEPLOY FIRST TIME ***" -BackgroundColor DarkGreen
            Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "BlobSampleData.json" -Recurse:$true -Force 
            Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "LS_AzureKeyVault.json" -Recurse:$true -Force 
            Publish-AdfV2FromJson @params
            #$ds2 = $gp.adftools_deployment_state.value
            $ds2 = $dstate
            Write-Host ($ds2 | ConvertTo-Json -Depth 5) -BackgroundColor Green
            $ds2.Deployed | Should -Not -BeNullOrEmpty
            $ds2.Deployed.Count | Should -Be 2
            Should -Invoke -CommandName New-AzResource -Times 2
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
            #$ds3 = $gp.adftools_deployment_state.value
            $ds3 = $dstate
            Write-Host ($ds3 | ConvertTo-Json -Depth 5) -BackgroundColor Green
            $ds3.Deployed.Count | Should -Be 1
        }

    } 

}
