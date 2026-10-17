<#
.SYNOPSIS
Deletes selected objects from Azure Data Factory instance (service).

.DESCRIPTION
Deletes objects from Azure Data Factory instance (service) that match given name patterns, or that a deployment with given publish option would deploy.
Objects are deleted in order: triggers, pipelines, data flows, datasets, linked services, credentials, integration runtimes. Started triggers are stopped first.
When an object is referenced by another one, the referencing object is deleted first, but only if it is selected too. Otherwise the function stops with an error.
Any failed deletion stops the function.

.PARAMETER ResourceGroupName
Resource Group Name of target ADF service.

.PARAMETER DataFactoryName
Name of target ADF service.

.PARAMETER Pattern
One or more wildcard patterns of objects to be deleted, in format: type.name[@folder]
The same format as in Includes/Excludes of the publish option, e.g.:
'pipeline.PL_Old*', 'dataset.*', 'pipeline.*@Archive', 'pipeline.*@Archive*' (Archive and its subfolders)
Only pipelines, datasets and data flows have folders.

.PARAMETER Option
Publish option (see New-AdfPublishOption). Deletes the objects that a deployment with this option would deploy, i.e. matching Includes and not matching Excludes.
Note: when the option has no Includes, all objects except those in Excludes are deleted.

.EXAMPLE
Remove-AdfObjects -ResourceGroupName 'rg-devops-factory' -DataFactoryName 'SQLPlayerDemo' -Pattern 'pipeline.PL_Old*', 'dataset.DS_Old*'

.EXAMPLE
# Delete all pipelines from folder 'Archive' and its subfolders, but show only what would be deleted
Remove-AdfObjects -ResourceGroupName 'rg-devops-factory' -DataFactoryName 'SQLPlayerDemo' -Pattern 'pipeline.*@Archive*' -WhatIf

.EXAMPLE
# "Reverse deployment": delete objects selected by deployment config file
$opt = New-AdfPublishOption -FilePath '.\deployment\rules.csv'
Remove-AdfObjects -ResourceGroupName 'rg-devops-factory' -DataFactoryName 'SQLPlayerDemo' -Option $opt

.OUTPUTS
Names (type.name) of deleted objects.

.LINK
Online version: https://github.com/SQLPlayer/azure.datafactory.tools/
#>
function Remove-AdfObjects {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Pattern')]
    [OutputType([String[]])]
    param (
        [parameter(Mandatory = $true)] [String] $ResourceGroupName,
        [parameter(Mandatory = $true)] [String] $DataFactoryName,
        [parameter(Mandatory = $true, ParameterSetName = 'Pattern')] [String[]] $Pattern,
        [parameter(Mandatory = $true, ParameterSetName = 'Option')] [AdfPublishOption] $Option
    )

    Write-Debug "BEGIN: Remove-AdfObjects(ResourceGroupName=$ResourceGroupName, DataFactoryName=$DataFactoryName)"

    $adfIns = Get-AdfFromService -FactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName

    if ($PSCmdlet.ParameterSetName -eq 'Pattern') {
        $patterns = @($Pattern)
    } else {
        $patterns = @($Option.Includes.Keys) + @($Option.Excludes.Keys)
    }
    $folders = @{}
    if (@($patterns | Where-Object { $_ -like '*@*' }).Count -gt 0) {
        $folders = Get-AdfObjectFolder -adfInstance $adfIns
    }

    $matching = @($adfIns.AllObjects() | Where-Object {
        $simtype = Get-SimplifiedType -Type $_.GetType().Name
        $fullName = "$simtype.$($_.Name)"
        $folder = if ($folders.ContainsKey($fullName)) { $folders[$fullName] } else { '' }
        if ($PSCmdlet.ParameterSetName -eq 'Pattern') {
            $isMatch = $false
            foreach ($p in $Pattern) {
                $arr = $p.Split('@')
                if ($fullName -like $arr[0] -and ($arr.Count -le 1 -or $folder -like $arr[1])) { $isMatch = $true }
            }
            $isMatch
        } else {
            $oname = [AdfObjectName]::new($_.Name, $simtype, $folder)
            -not $oname.IsNameExcluded($Option)
        }
    })
    # Delete referencing objects before the objects they reference
    $typeOrder = @('Trigger', 'Pipeline', 'DataFlow', 'Dataset', 'LinkedService', 'Credential', 'IntegrationRuntime')
    $selected = @(foreach ($type in $typeOrder) {
        $matching | Where-Object { (Get-SimplifiedType -Type $_.GetType().Name) -eq $type }
    })

    Write-Host "Found $($selected.Count) object(s) to delete."

    # Ask about all objects first, so a cascade never deletes an object that was not confirmed
    $confirmed = @($selected | Where-Object {
        $PSCmdlet.ShouldProcess("[$(Get-SimplifiedType -Type $_.GetType().Name)].[$($_.Name)] in $DataFactoryName", 'Remove')
    })

    $deleted = [System.Collections.ArrayList]::new()
    foreach ($obj in $confirmed) {
        Remove-AdfObject -obj $obj -adfInstance $adfIns -Selection $confirmed -Deleted $deleted
    }

    Write-Host "Deleted $($deleted.Count) object(s) from ADF service."
    Write-Debug "END: Remove-AdfObjects()"
    return [String[]] @($deleted | ForEach-Object { "$(Get-SimplifiedType -Type $_.GetType().Name).$($_.Name)" })
}
