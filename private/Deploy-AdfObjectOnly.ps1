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
    $body = (Get-Content -Path $obj.FileName | Out-String)
    Write-Debug -Message $body
    $json = $body | ConvertFrom-Json

    $type = $obj.Type
    if ($script:PublishMethod -eq "AzResource") { $type = "AzResource" }
    switch -Exact ($type)
    {
        'integrationRuntime'
        {
            Set-StrictMode -Version 1.0
            if ($json.properties.type -eq "SelfHosted") {
                $desc = if ($null -eq $json.properties.description) { " " } else { $json.properties.description }
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
                # This is workaround: Deployment from ARM template as an exception.
                # PowerShell's method is not ready to accept parameters for dataFlowProperties.
                $deploymentName = "ADFToolsPS-{0:yyyyMMdd-HHmmss}-{1:x}" -f (Get-Date), (Get-Random);
                $params = @{ name = $json.name; factoryName = "$DataFactoryName"; computeType = $dfp.computeType; coreCount = $dfp.coreCount; timeToLive = $dfp.timeToLive; location = $computeIR.location}
                New-AzResourceGroupDeployment -Name "$deploymentName" -Mode 'Incremental' -ResourceGroupName "$ResourceGroupName" `
                  -TemplateFile "$PSScriptRoot\azure-managed-ir-arm.json" `
                  -TemplateParameterObject $params | Out-Null
            }
            else {
                Write-Error "Deployment for this kind of Integration Runtime is not supported yet."
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
        'AzResource'
        {
            $resType = Get-AzureResourceType $obj.Type
            New-AzResource `
            -ResourceType $resType `
            -ResourceGroupName $resourceGroupName `
            -Name "$DataFactoryName/$($obj.Name)" `
            -ApiVersion "2018-06-01" `
            -Properties $json `
            -IsFullObject -Force | Out-Null
        }
        default
        {
            Write-Error "Type $($obj.Type) is not supported."
        }
    }

    $obj.Deployed = $true;

}
