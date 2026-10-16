function Deploy-AdfObjectOnly {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [AdfObject] $obj
    )

    if ($obj.Deployed) { 
        Write-Verbose ("The object is already deployed.")
        return; 
    }
    #Write-Host "Deploying object: $($obj.Name) ($($obj.DependsOn.Count) dependency/ies)"
    #Write-Verbose "  Type: $($obj.Type)"
    $adf = $obj.Adf
    $ResourceGroupName = $adf.ResourceGroupName
    $DataFactoryName = $adf.Name

    Write-Verbose ("Ready to deploy from file: {0}" -f $obj.FileName)
    $body = (Get-Content -Path $obj.FileName -Encoding "UTF8" | Out-String)
    Write-Debug -Message $body
    $json = $body | ConvertFrom-Json

    # Retry temporary API errors (e.g. time-outs) #295
    $maxRetries = if ($null -ne $adf.PublishOptions) { $adf.PublishOptions.MaxRetries } else { 3 }
    $activity = "Deployment of $($obj.FullName($true))"

    $type = $obj.Type
    if ($script:PublishMethod -eq "AzResource") { $type = "AzResource" }
    # Global parameters is being deployed with different method:
    if ($obj.Type -eq "factory") { $type = "GlobalParameters" }

    switch -Exact ($type)
    {
        'integrationRuntime'
        {
            Set-StrictMode -Version 1.0
            $desc = if ($null -eq $json.properties.description) { " " } else { $json.properties.description }
            if ($json.properties.type -eq "SelfHosted") {
                $linkedIR = $json.properties.typeProperties.linkedInfo

                if ($null -eq $linkedIR) {
                    Write-Verbose -Message "Integration Runtime type detected: Self-Hosted"
                    Invoke-AdfWithRetry -Activity $activity -MaxRetries $maxRetries -ScriptBlock {
                        Set-AzDataFactoryV2IntegrationRuntime `
                        -ResourceGroupName $ResourceGroupName `
                        -DataFactoryName $DataFactoryName `
                        -Name $json.name `
                        -Type $json.properties.type `
                        -Description $desc `
                        -Force -ErrorAction Stop | Out-Null
                    }
                } 
                else 
                {
                    Write-Verbose -Message "Integration Runtime type detected: Linked Self-Hosted"
                    Invoke-AdfWithRetry -Activity $activity -MaxRetries $maxRetries -ScriptBlock {
                        Set-AzDataFactoryV2IntegrationRuntime `
                        -ResourceGroupName $ResourceGroupName `
                        -DataFactoryName $DataFactoryName `
                        -Name $json.name `
                        -Type $json.properties.type `
                        -Description $desc `
                        -SharedIntegrationRuntimeResourceId $linkedIR.resourceId `
                        -Force -ErrorAction Stop | Out-Null
                    }
                }
            }
            elseif ($json.properties.type -eq "Managed") {
                Write-Verbose -Message "Integration Runtime type detected: Azure Managed"
                $computeIR = $json.properties.typeProperties.computeProperties
                $dfp = $computeIR.dataFlowProperties
                Invoke-AdfWithRetry -Activity $activity -MaxRetries $maxRetries -ScriptBlock {
                    Set-AzDataFactoryV2IntegrationRuntime `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $json.name `
                    -Type $json.properties.type `
                    -Description $desc `
                    -DataFlowComputeType $dfp.computeType `
                    -DataFlowTimeToLive $dfp.timeToLive `
                    -DataFlowCoreCount $dfp.coreCount `
                    -Location $computeIR.location `
                    -Force -ErrorAction Stop | Out-Null
                }
            }
            else {
                throw "ADFT0012: Deployment for this kind of Integration Runtime is not supported yet."
            }
        }
        'linkedService'
        {
            Invoke-AdfWithRetry -Activity $activity -MaxRetries $maxRetries -ScriptBlock {
                Set-AzDataFactoryV2LinkedService `
                -ResourceGroupName $ResourceGroupName `
                -DataFactoryName $DataFactoryName `
                -Name $obj.Name `
                -DefinitionFile $obj.FileName `
                -Force -ErrorAction Stop | Out-Null
            }
        }
        'pipeline'
        {
            Invoke-AdfWithRetry -Activity $activity -MaxRetries $maxRetries -ScriptBlock {
                Set-AzDataFactoryV2Pipeline `
                -ResourceGroupName $ResourceGroupName `
                -DataFactoryName $DataFactoryName `
                -Name $obj.Name `
                -DefinitionFile $obj.FileName `
                -Force -ErrorAction Stop | Out-Null
            }
        }
        'dataset'
        {
            Invoke-AdfWithRetry -Activity $activity -MaxRetries $maxRetries -ScriptBlock {
                Set-AzDataFactoryV2Dataset `
                -ResourceGroupName $ResourceGroupName `
                -DataFactoryName $DataFactoryName `
                -Name $obj.Name `
                -DefinitionFile $obj.FileName `
                -Force -ErrorAction Stop | Out-Null
            }
        }
        'dataflow'
        {
            Invoke-AdfWithRetry -Activity $activity -MaxRetries $maxRetries -ScriptBlock {
                Set-AzDataFactoryV2DataFlow `
                -ResourceGroupName $ResourceGroupName `
                -DataFactoryName $DataFactoryName `
                -Name $obj.Name `
                -DefinitionFile $obj.FileName `
                -Force -ErrorAction Stop | Out-Null
            }
        }
        'trigger'
        {
            Invoke-AdfWithRetry -Activity $activity -MaxRetries $maxRetries -ScriptBlock {
                Set-AzDataFactoryV2Trigger `
                -ResourceGroupName $ResourceGroupName `
                -DataFactoryName $DataFactoryName `
                -Name $obj.Name `
                -DefinitionFile $obj.FileName `
                -Force -ErrorAction Stop | Out-Null
            }
        }
        'credential'
        {
            $resType = Get-AzureResourceType $obj.Type
            $resName = $obj.AzureResourceName()

            Invoke-AdfWithRetry -Activity $activity -MaxRetries $maxRetries -ScriptBlock {
                New-AzResource `
                -ResourceType $resType `
                -ResourceGroupName $ResourceGroupName `
                -ResourceName "$resName" `
                -ApiVersion "2018-06-01" `
                -Properties $json `
                -IsFullObject -Force -ErrorAction Stop | Out-Null
            }
        }
        'AzResource'
        {
            $resType = Get-AzureResourceType $obj.Type
            $resName = $obj.AzureResourceName()

            Invoke-AdfWithRetry -Activity $activity -MaxRetries $maxRetries -ScriptBlock {
                New-AzResource `
                -ResourceType $resType `
                -ResourceGroupName $resourceGroupName `
                -ResourceName "$resName" `
                -ApiVersion "2018-06-01" `
                -Properties $json `
                -IsFullObject -Force -ErrorAction Stop | Out-Null
            }
        }
        'GlobalParameters'
        {
            $adf.GlobalFactory.GlobalParameters = $json
            $adf.GlobalFactory.body = $body
            Update-GlobalParameters -adf $adf
        }
        default
        {
            throw "ADFT0013: Type $($obj.Type) is not supported."
        }
    }

    $obj.Deployed = $true;

}
