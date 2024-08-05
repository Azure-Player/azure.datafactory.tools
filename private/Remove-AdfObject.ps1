function Remove-AdfObject {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adfSource,
        [parameter(Mandatory = $true)] $obj,
        [parameter(Mandatory = $true)] $adfInstance
    )

    Write-Debug "BEGIN: Remove-AdfObject()"

    $name = $obj.Name
    $err = $null
    $ErrorMessage = $null
    $simtype = Get-SimplifiedType -Type $obj.GetType().Name
    if ($simtype -eq 'AdfObject') {
        $simtype = ConvertTo-AdfType -AzType $adfTargetObj.Type
    }

    [AdfObjectName] $oname = [AdfObjectName]::new("$simType.$name")
    $IsExcluded = $oname.IsNameExcluded($adfSource.PublishOptions)
    if (-not $IsExcluded) {
        Write-Host "Removing object: [$simtype].[$name]"
        $action = $simtype
    } else {
        if ($adfSource.PublishOptions.DoNotDeleteExcludedObjects) {
            Write-Verbose "Object [$simtype].[$name] won't be deleted as publish option 'DoNotDeleteExcludedObjects' = true."
            $action = "DoNothing"
        } else {
            Write-Host "Removing excluded object: [$simtype].[$name] as publish option 'DoNotDeleteExcludedObjects' = false."
            $action = $simtype
        }
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
                    -Force -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "DataFlow" {
                Remove-AzDataFactoryV2DataFlow `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $name `
                    -Force -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "Pipeline" {
                Remove-AzDataFactoryV2Pipeline `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $name `
                    -Force -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "LinkedService" {
                Remove-AzDataFactoryV2LinkedService `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $name `
                    -Force -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "IntegrationRuntime" {
                Remove-AzDataFactoryV2IntegrationRuntime `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $name `
                    -Force -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "Trigger" {
                # Stop trigger if enabled before delete it
                if ($obj.RuntimeState -eq 'Started') {
                    Write-Verbose "Disabling trigger: $name..." 
                    Stop-AzDataFactoryV2Trigger `
                        -ResourceGroupName $ResourceGroupName `
                        -DataFactoryName $DataFactoryName `
                        -Name $name `
                        -Force -ErrorVariable err -ErrorAction Stop | Out-Null
                }
                Remove-AzDataFactoryV2Trigger `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $name `
                    -Force -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "Credential" {
                Remove-AdfObjectRestAPI `
                    -type_plural 'credentials' `
                    -name $name `
                    -adfInstance $adfInstance `
                    -ErrorVariable err -ErrorAction Stop | Out-Null
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
        Write-Debug "Error caught when deleting:`n$err"
        $ErrorMessage = $_.Exception.Message
    }
    # Finally {
    #     if ($null -eq $ErrorMessage -and $null -ne $err) {
    #         if ($err.Count -gt 0) { $ErrorMessage = $err[0] }
    #     }
    # }

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

    Write-Debug "END: Remove-AdfObject()"

}
