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
                    Set-AzDataFactoryV2IntegrationRuntime `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $json.name `
                    -Type $json.properties.type `
                    -Description $desc `
                    -Force | Out-Null
                } 
                else 
                {
                    Write-Verbose -Message "Integration Runtime type detected: Linked Self-Hosted"
                    Set-AzDataFactoryV2IntegrationRuntime `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $json.name `
                    -Type $json.properties.type `
                    -Description $desc `
                    -SharedIntegrationRuntimeResourceId $linkedIR.resourceId `
                    -Force | Out-Null
                }
            }
            elseif ($json.properties.type -eq "Managed") {
                Write-Verbose -Message "Integration Runtime type detected: Azure Managed"
                $computeIR = $json.properties.typeProperties.computeProperties
                $dfp = $computeIR.dataFlowProperties
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
                -Force | Out-Null
            }
            else {
                Write-Error "ADFT0012: Deployment for this kind of Integration Runtime is not supported yet."
            }
        }
        'linkedService'
        {
            Set-AzDataFactoryV2LinkedService `
            -ResourceGroupName $ResourceGroupName `
            -DataFactoryName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            -Force | Out-Null
        }
        'pipeline'
        {
            Set-AzDataFactoryV2Pipeline `
            -ResourceGroupName $ResourceGroupName `
            -DataFactoryName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            -Force | Out-Null
        }
        'dataset'
        {
            Set-AzDataFactoryV2Dataset `
            -ResourceGroupName $ResourceGroupName `
            -DataFactoryName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            -Force | Out-Null
        }
        'dataflow'
        {
            Set-AzDataFactoryV2DataFlow `
            -ResourceGroupName $ResourceGroupName `
            -DataFactoryName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            -Force | Out-Null
        }
        'trigger'
        {
            Set-AzDataFactoryV2Trigger `
            -ResourceGroupName $ResourceGroupName `
            -DataFactoryName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            -Force | Out-Null
        }
        'credential'
        {
            Write-Warning "Credentials are not yet supported. The deployment for the object is skipped."
            Write-Warning "Any reference to the object causes error, unless to deploy it before."
        }
        'AzResource'
        {
            $resType = Get-AzureResourceType $obj.Type
            $resName = $obj.AzureResourceName()

            New-AzResource `
            -ResourceType $resType `
            -ResourceGroupName $resourceGroupName `
            -ResourceName "$resName" `
            -ApiVersion "2018-06-01" `
            -Properties $json `
            -IsFullObject -Force | Out-Null
        }
        'GlobalParameters'
        {
            $adf.GlobalFactory.GlobalParameters = $json
            $adf.GlobalFactory.body = $body
            Update-GlobalParameters -adf $adf
        }
        default
        {
            Write-Error "ADFT0013: Type $($obj.Type) is not supported."
        }
    }

    $obj.Deployed = $true;

}
