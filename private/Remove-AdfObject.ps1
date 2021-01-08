function Remove-AdfObject {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adfSource,
        [parameter(Mandatory = $true)] $obj,
        [parameter(Mandatory = $true)] $adfInstance
    )

    $name = $obj.Name
    $err = $null
    $ErrorMessage = $null
    $simtype = Get-SimplifiedType -Type $obj.GetType().Name

    [AdfObjectName] $oname = [AdfObjectName]::new("$simType.$name")
    $IsExcluded = $oname.IsNameExcluded($adfSource.PublishOptions)
    if (-not $IsExcluded) {
        Write-Host "Removing object: [$simtype].[$name]"
        $action = $simtype
    } else {
        $action = "DoNothing"
        Write-Verbose "Object [$simtype].[$name] won't be deleted as publish option 'DoNotDeleteExcludedObjects' = true."
    }

    Try 
    {
        switch -Exact ($action)
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
            "DoNothing" {

            }
            default
            {
                Write-Error "ADFT0018: Type $($obj.GetType().Name) is not supported."
            }
        }
    }
    Catch {
        Write-Debug "$err"
        $ErrorMessage = $_.Exception.Message
    }

    # if ($ErrorMessage -match 'Error Code: TriggerEnabledCannotUpdate')
    # {
    #     Write-host "Disabling trigger: $name..." 
    #     Stop-AzDataFactoryV2Trigger `
    #     -ResourceGroupName $ResourceGroupName `
    #     -DataFactoryName $DataFactoryName `
    #     -Name $name `
    #     -Force | Out-Null
    #     Remove-AdfObject -obj $obj -adfInstance $adfInstance
    # }

    if ($ErrorMessage -match 'deleted since it is referenced by (?<RefName>.+)\.')
    {
        Write-Verbose "The document cannot be deleted since it is referenced by $($Matches.RefName)."
        #$Matches.RefName
        $refobj = $adfInstance.AllObjects() | Where-Object { $_.Name -eq $Matches.RefName }
        $refobj | ForEach-Object {
            Remove-AdfObject -adfSource $adfSource -obj $_ -adfInstance $adfInstance
        }
        Remove-AdfObject -adfSource $adfSource -obj $obj -adfInstance $adfInstance
    } elseif ($null -ne $ErrorMessage) {
        #Rethrow exception
        throw $ErrorMessage
    }

}
