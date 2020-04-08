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
    # $obj
    # $adf
    $adf = $obj.Adf
    $ResourceGroupName = $adf.ResourceGroupName
    $DataFactoryName = $adf.Name

    Write-Verbose ("Ready to deploy from file: {0}" -f $obj.FileName)
    $body = (Get-Content -Path $obj.FileName | Out-String)
    Write-Debug -Message $body

    switch -Exact ($obj.Type)
    {
        'Microsoft.DataFactory/factories/linkedservices'
        {
            Set-AzDataFactoryV2LinkedService `
            -ResourceGroupName $ResourceGroupName `
            -DataFactoryName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            -Force | Out-Null
        }
        'Microsoft.DataFactory/factories/pipelines'
        {
            Set-AzDataFactoryV2Pipeline `
            -ResourceGroupName $ResourceGroupName `
            -DataFactoryName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            -Force | Out-Null
        }
        'Microsoft.DataFactory/factories/datasets'
        {
            Set-AzDataFactoryV2Dataset `
            -ResourceGroupName $ResourceGroupName `
            -DataFactoryName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            -Force | Out-Null
        }
        'Microsoft.DataFactory/factories/dataflows'
        {
            Set-AzDataFactoryV2DataFlow `
            -ResourceGroupName $ResourceGroupName `
            -DataFactoryName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            -Force | Out-Null
        }
        default
        {
            Write-Error "Type $($obj.Type) is not supported."
        }
    }

    $obj.Deployed = $true;

}
