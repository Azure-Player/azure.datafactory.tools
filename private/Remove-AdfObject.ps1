function Remove-AdfObject {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false)] [Adf] $adfSource,
        [parameter(Mandatory = $true)] $obj,
        [parameter(Mandatory = $true)] $adfInstance,
        # When set, a referencing object is deleted first only if it is in this list; otherwise ADFT0034 is thrown
        [parameter(Mandatory = $false)] [array] $Selection,
        # When set, collects deleted objects; objects already in it are skipped
        [parameter(Mandatory = $false)] [System.Collections.ArrayList] $Deleted
    )

    Write-Debug "BEGIN: Remove-AdfObject()"

    $ResourceGroupName = $adfInstance.ResourceGroupName
    $DataFactoryName = $adfInstance.Name
    $name = $obj.Name
    $ErrorMessage = $null
    $simtype = Get-SimplifiedType -Type $obj.GetType().Name
    if ($simtype -eq 'AdfObject') {
        $simtype = ConvertTo-AdfType -AzType $obj.Type
    }

    if ($null -ne $Deleted -and $Deleted.Contains($obj)) {
        Write-Verbose "Object [$simtype].[$name] has already been deleted."
        Write-Debug "END: Remove-AdfObject()"
        return
    }

    $action = $simtype
    if ($null -eq $adfSource) {
        Write-Host "Removing object: [$simtype].[$name]"
    } else {
        # The folder is only needed (and read from the service) when any filter rule uses '@folder'
        $folder = ''
        if ($adfSource.PublishOptions.HasFolderRules()) {
            $folder = Get-AdfObjectFolderFromService -adfInstance $adfInstance -type $simtype -name $name
        }
        [AdfObjectName] $oname = [AdfObjectName]::new($name, $simtype, $folder)
        $IsExcluded = $oname.IsNameExcluded($adfSource.PublishOptions)
        if (-not $IsExcluded) {
            Write-Host "Removing object: [$simtype].[$name]"
        } else {
            if ($adfSource.PublishOptions.DoNotDeleteExcludedObjects) {
                Write-Host "Skipping excluded object: [$simtype].[$name] as publish option 'DoNotDeleteExcludedObjects' = true."
                $action = "DoNothing"
            } else {
                Write-Host "Removing excluded object: [$simtype].[$name] as publish option 'DoNotDeleteExcludedObjects' = false."
            }
        }
    }

    Try
    {
        Invoke-AdfWithRetry -Activity "Removing [$simtype].[$name]" -ScriptBlock {
            switch -Exact ($action)
            {
                "Dataset" {
                    Remove-AzDataFactoryV2Dataset `
                        -ResourceGroupName $ResourceGroupName `
                        -DataFactoryName $DataFactoryName `
                        -Name $name `
                        -Force -ErrorAction Stop | Out-Null
                }
                "DataFlow" {
                    Remove-AzDataFactoryV2DataFlow `
                        -ResourceGroupName $ResourceGroupName `
                        -DataFactoryName $DataFactoryName `
                        -Name $name `
                        -Force -ErrorAction Stop | Out-Null
                }
                "Pipeline" {
                    Remove-AzDataFactoryV2Pipeline `
                        -ResourceGroupName $ResourceGroupName `
                        -DataFactoryName $DataFactoryName `
                        -Name $name `
                        -Force -ErrorAction Stop | Out-Null
                }
                "LinkedService" {
                    Remove-AzDataFactoryV2LinkedService `
                        -ResourceGroupName $ResourceGroupName `
                        -DataFactoryName $DataFactoryName `
                        -Name $name `
                        -Force -ErrorAction Stop | Out-Null
                }
                "IntegrationRuntime" {
                    Remove-AzDataFactoryV2IntegrationRuntime `
                        -ResourceGroupName $ResourceGroupName `
                        -DataFactoryName $DataFactoryName `
                        -Name $name `
                        -Force -ErrorAction Stop | Out-Null
                }
                "Trigger" {
                    # Stop trigger if enabled before delete it
                    if ($obj.RuntimeState -eq 'Started') {
                        Write-Verbose "Disabling trigger: $name..."
                        Stop-AzDataFactoryV2Trigger `
                            -ResourceGroupName $ResourceGroupName `
                            -DataFactoryName $DataFactoryName `
                            -Name $name `
                            -Force -ErrorAction Stop | Out-Null
                    }
                    Remove-AzDataFactoryV2Trigger `
                        -ResourceGroupName $ResourceGroupName `
                        -DataFactoryName $DataFactoryName `
                        -Name $name `
                        -Force -ErrorAction Stop | Out-Null
                }
                "Credential" {
                    Remove-AdfObjectRestAPI `
                        -type_plural 'credentials' `
                        -name $name `
                        -adfInstance $adfInstance `
                        -ErrorAction Stop | Out-Null
                }
                "DoNothing" {

                }
                default
                {
                    throw "ADFT0018: Type $($obj.GetType().Name) is not supported."
                }
            }
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        Write-Debug "Error caught when deleting:`n$ErrorMessage"
    }

    if ($ErrorMessage -match 'deleted since it is referenced by (?<RefName>.+)\.')
    {
        $refName = $Matches.RefName
        Write-Verbose "The document cannot be deleted since it is referenced by $refName."
        $refobj = @($adfInstance.AllObjects() | Where-Object { $_.Name -eq $refName })
        if ($null -ne $Selection) {
            $notSelected = @($refobj | Where-Object { $Selection -notcontains $_ })
            if ($refobj.Count -eq 0 -or $notSelected.Count -gt 0) {
                throw "ADFT0034: [$simtype].[$name] cannot be deleted since it is referenced by $refName, which is not selected for deletion."
            }
        }
        $refobj | ForEach-Object {
            Remove-AdfObject -adfSource $adfSource -obj $_ -adfInstance $adfInstance -Selection $Selection -Deleted $Deleted
        }
        Remove-AdfObject -adfSource $adfSource -obj $obj -adfInstance $adfInstance -Selection $Selection -Deleted $Deleted
    } elseif ($null -ne $ErrorMessage) {
        #Rethrow exception
        throw $ErrorMessage
    } elseif ($action -ne 'DoNothing') {
        if ($null -ne $Deleted) { $Deleted.Add($obj) | Out-Null }
        if ($null -ne $adfSource) { $adfSource.DeletedObjectNames.Add("$simtype.$name") | Out-Null }
    }

    Write-Debug "END: Remove-AdfObject()"

}
