BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName
    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {

    # -------------------------------------------------------------------------
    # Issue #440 - DeleteNotInSource with -FilterFilePath
    # #512: objects skipped as excluded were reported as deleted
    # #513: @folder rules never matched objects that exist only in ADF
    # -------------------------------------------------------------------------
    Describe 'Remove-AdfObjectIfNotInSource (Issue #440)' -Tag 'Unit' {

        BeforeAll {
            function New-TestSource {
                param ([string[]] $Includes = @(), [string[]] $Excludes = @())
                $adf = New-Object -TypeName Adf
                $adf.Name = 'adf-test'
                $adf.ResourceGroupName = 'rg-test'
                $opt = New-AdfPublishOption
                $opt.DeleteNotInSource = $true
                $Includes | ForEach-Object { $opt.Includes.Add($_, '') }
                $Excludes | ForEach-Object { $opt.Excludes.Add($_, '') }
                $adf.PublishOptions = $opt
                return $adf
            }

            function New-TestTarget {
                $ins = New-Object -TypeName AdfInstance
                $ins.Id = '/subscriptions/sub-id/resourceGroups/rg-test/providers/Microsoft.DataFactory/factories/adf-test'
                $ins.Name = 'adf-test'
                $ins.ResourceGroupName = 'rg-test'
                return $ins
            }

            # Folders of the objects in the target ADF, as returned by the REST API
            $script:ServiceFolders = @{
                'pipelines/PL_Sales_Old'  = 'Sales/Daily'
                'pipelines/PL_HR_Old'     = 'HR'
                'datasets/DS_Sales_Old'   = 'Sales'
            }
        }

        BeforeEach {
            $ErrorActionPreference = 'Continue'
            Mock Write-Host { }
            Mock Remove-AzDataFactoryV2Pipeline { }
            Mock Remove-AzDataFactoryV2Dataset { }
            Mock Remove-AzDataFactoryV2Trigger { }
            Mock Stop-AzDataFactoryV2Trigger { }
            Mock Invoke-AzRestMethod {
                $key = ($Uri -split '/factories/adf-test/')[1].Split('?')[0]
                $folder = $script:ServiceFolders[$key]
                $props = if ($folder) { @{ folder = @{ name = $folder } } } else { @{} }
                [PSCustomObject]@{
                    StatusCode = 200
                    Content    = (@{ name = $key.Split('/')[1]; properties = $props } | ConvertTo-Json -Depth 5)
                }
            }
        }

        Context 'When the object is excluded and DoNotDeleteExcludedObjects = true (#512)' {

            It 'Should not delete the object' {
                $adf = New-TestSource -Includes 'pipeline.PL_Keep*'
                $obj = [AdfPSPipeline]::new('PL_Other')
                Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $obj -adfInstance (New-TestTarget)
                Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 0 -Exactly
            }

            It 'Should not count the object as deleted' {
                $adf = New-TestSource -Includes 'pipeline.PL_Keep*'
                $obj = [AdfPSPipeline]::new('PL_Other')
                Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $obj -adfInstance (New-TestTarget)
                $adf.DeletedObjectNames.Count | Should -Be 0
            }

            It 'Should log the skipped object with Write-Host' {
                $adf = New-TestSource -Includes 'pipeline.PL_Keep*'
                $obj = [AdfPSPipeline]::new('PL_Other')
                Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $obj -adfInstance (New-TestTarget)
                Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { "$Object" -like '*PL_Other*DoNotDeleteExcludedObjects*' }
            }
        }

        Context 'When the object is not excluded (#512)' {

            It 'Should delete the pipeline and count it as deleted' {
                $adf = New-TestSource
                $obj = [AdfPSPipeline]::new('PL_Old')
                Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $obj -adfInstance (New-TestTarget)
                Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'PL_Old' -and $ResourceGroupName -eq 'rg-test' -and $DataFactoryName -eq 'adf-test'
                }
                $adf.DeletedObjectNames | Should -Be @('Pipeline.PL_Old')
            }

            It 'Should stop and delete a started trigger listed in the filter file' {
                $adf = New-TestSource -Includes 'trigger.TR_Removed'
                $obj = [AdfPSTrigger]::new('TR_Removed', 'Started')
                Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $obj -adfInstance (New-TestTarget)
                Should -Invoke Stop-AzDataFactoryV2Trigger -Times 1 -Exactly -ParameterFilter { $Name -eq 'TR_Removed' }
                Should -Invoke Remove-AzDataFactoryV2Trigger -Times 1 -Exactly -ParameterFilter { $Name -eq 'TR_Removed' }
                $adf.DeletedObjectNames | Should -Be @('Trigger.TR_Removed')
            }

            It 'Should not count the object as deleted when the removal fails' {
                Mock Remove-AzDataFactoryV2Pipeline { Write-Error 'Simulated: AuthorizationFailed' }
                $adf = New-TestSource
                $obj = [AdfPSPipeline]::new('PL_Old')
                { Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $obj -adfInstance (New-TestTarget) } | Should -Throw '*AuthorizationFailed*'
                $adf.DeletedObjectNames.Count | Should -Be 0
            }
        }

        Context 'When filter rules use @folder (#513)' {

            It 'Should delete a pipeline in a folder matched by an include rule' {
                $adf = New-TestSource -Includes 'pipeline.*@Sales*'
                $obj = [AdfPSPipeline]::new('PL_Sales_Old')
                Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $obj -adfInstance (New-TestTarget)
                Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 1 -Exactly -ParameterFilter { $Name -eq 'PL_Sales_Old' }
                $adf.DeletedObjectNames | Should -Be @('Pipeline.PL_Sales_Old')
            }

            It 'Should delete a dataset in a folder matched by an include rule' {
                $adf = New-TestSource -Includes 'dataset.*@Sales'
                $obj = [AdfPSDataset]::new('DS_Sales_Old')
                Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $obj -adfInstance (New-TestTarget)
                Should -Invoke Remove-AzDataFactoryV2Dataset -Times 1 -Exactly -ParameterFilter { $Name -eq 'DS_Sales_Old' }
            }

            It 'Should not delete a pipeline in a folder not matched by any include rule' {
                $adf = New-TestSource -Includes 'pipeline.*@Sales*'
                $obj = [AdfPSPipeline]::new('PL_HR_Old')
                Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $obj -adfInstance (New-TestTarget)
                Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 0 -Exactly
                $adf.DeletedObjectNames.Count | Should -Be 0
            }

            It 'Should not delete a pipeline in a folder matched by an exclude rule' {
                $adf = New-TestSource -Excludes 'pipeline.*@HR'
                $obj = [AdfPSPipeline]::new('PL_HR_Old')
                Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $obj -adfInstance (New-TestTarget)
                Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 0 -Exactly
                $adf.DeletedObjectNames.Count | Should -Be 0
            }

            It 'Should still match a rule without folder for a pipeline in a folder' {
                $adf = New-TestSource -Includes 'pipeline.PL_Sales_Old', 'pipeline.*@Other'
                $obj = [AdfPSPipeline]::new('PL_Sales_Old')
                Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $obj -adfInstance (New-TestTarget)
                Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 1 -Exactly -ParameterFilter { $Name -eq 'PL_Sales_Old' }
            }

            It 'Should not call the REST API when no rule uses @folder' {
                $adf = New-TestSource -Includes 'pipeline.*'
                $obj = [AdfPSPipeline]::new('PL_Sales_Old')
                Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $obj -adfInstance (New-TestTarget)
                Should -Invoke Invoke-AzRestMethod -Times 0 -Exactly
            }

            It 'Should fail when the folder cannot be read' {
                Mock Invoke-AzRestMethod { [PSCustomObject]@{ StatusCode = 403; Content = '{}' } }
                $adf = New-TestSource -Excludes 'pipeline.*@HR'
                $obj = [AdfPSPipeline]::new('PL_HR_Old')
                { Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $obj -adfInstance (New-TestTarget) } | Should -Throw '*403*'
                Should -Invoke Remove-AzDataFactoryV2Pipeline -Times 0 -Exactly
            }
        }

        Context 'DryRun plan with @folder rules (#513)' {

            It 'Should plan to delete only pipelines in folders matched by an include rule' {
                $adf = New-TestSource -Includes 'pipeline.*@Sales*'
                $ins = New-TestTarget
                $ins.Pipelines.Add([AdfPSPipeline]::new('PL_Sales_Old')) | Out-Null
                $ins.Pipelines.Add([AdfPSPipeline]::new('PL_HR_Old')) | Out-Null
                $plan = Get-DryRunPlan -adf $adf -targetAdfInstance $ins
                $plan.Delete | Should -Be @('pipeline.PL_Sales_Old')
            }
        }
    }
}
