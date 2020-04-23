function Remove-AdfObject {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] $obj,
        [parameter(Mandatory = $true)] $adfInstance
    )

    $name = $obj.Name
    Write-Host "Removing object: [$($obj.Name)]"
    $err = $null
    $ErrorMessage = $null
    $simtype = Get-SimplifiedType -Type $obj.GetType().Name

    Try 
    {
        switch -Exact ($simtype)
        {
            "Dataset" {
                Remove-AzDataFactoryV2Dataset `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $name `
                    -Force -ErrorVariable err | Out-Null
            }
            "DataFlow" {
                Remove-AzDataFactoryV2DataFlow `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $name `
                    -Force -ErrorVariable err | Out-Null
            }
            "Pipeline" {
                Remove-AzDataFactoryV2Pipeline `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $name `
                    -Force -ErrorVariable err | Out-Null
            }
            "LinkedService" {
                Remove-AzDataFactoryV2LinkedService `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $name `
                    -Force -ErrorVariable err | Out-Null
            }
            "IntegrationRuntime" {
                Remove-AzDataFactoryV2IntegrationRuntime `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $name `
                    -Force -ErrorVariable err | Out-Null
            }
            "Trigger" {
                Remove-AzDataFactoryV2Trigger `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $name `
                    -Force -ErrorVariable err | Out-Null
            }
            default
            {
                Write-Error "Type $($obj.GetType().Name) is not supported."
            }
        }
    }
    Catch {
        Write-Debug "$err"
        $ErrorMessage = $_.Exception.Message
    }

    if ($ErrorMessage -match 'deleted since it is referenced by (?<RefName>.+)\.')
    {
        #$Matches
        Write-Verbose "The document cannot be deleted since it is referenced by $($Matches.RefName)."
        #$Matches.RefName
        $refobj = $adfInstance.AllObjects() | Where-Object { $_.Name -eq $Matches.RefName }
        Remove-AdfObject -obj $refobj -adfInstance $adfInstance
        Remove-AdfObject -obj $obj -adfInstance $adfInstance
    } 

}
