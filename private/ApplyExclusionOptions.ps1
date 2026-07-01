function ApplyExclusionOptions {
    param(
        [Parameter(Mandatory=$True)] [Adf] $adf
    )

    Write-Debug "BEGIN: ApplyExclusionOptions()"
    
    $option = $adf.PublishOptions
    if ($option.Excludes.Keys.Count -gt 0 -and $option.Includes.Keys.Count -eq 0)
    {
        Write-Debug "ENTRY: ApplyExclusionOptions()::Excludes"
        $adf.AllObjects() | ForEach-Object {
            [AdfObject] $o = $_
            $o.ToBeDeployed = $true
        }
        $option.Excludes.Keys | ForEach-Object {
            $key = $_
            $adf.AllObjects() | ForEach-Object {
                [AdfObject] $o = $_
                $nonDeployable = $o.IsNameMatch($key)
                if ($nonDeployable) { $o.ToBeDeployed = $false }
                #Write-Verbose "- $($o.FullName($true)).ToBeDeployed = $($o.ToBeDeployed)"
            }
        }
    }
    
    if ($option.Includes.Keys.Count -gt 0)
    {
        Write-Debug "ENTRY: ApplyExclusionOptions()::Includes"
        $adf.AllObjects() | ForEach-Object {
            [AdfObject] $o = $_
            $o.ToBeDeployed = $false
        }
        $option.Includes.Keys | ForEach-Object {
            $key = $_
            $adf.AllObjects() | ForEach-Object {
                [AdfObject] $o = $_
                $deployable = $o.IsNameMatch($key)
                if ($deployable) { $o.ToBeDeployed = $true }
                #Write-Verbose "- $($o.FullName($true)).ToBeDeployed = $($o.ToBeDeployed)"
            }
        }
    }

    #ToBeDeployedStat -adf $adf

    Write-Debug "END: ApplyExclusionOptions()"
}

function ToBeDeployedStat {
    param(
        [Parameter(Mandatory=$True)] [Adf] $adf,
        [Parameter(Mandatory=$False)] $targetAdfInstance,
        [switch] $TerraformStyle
    )

    $ToBeDeployedList = ($adf.AllObjects() | Where-Object { $_.ToBeDeployed -eq $true } | ToArray)
    $i = $ToBeDeployedList.Count
    Write-Host "# Number of objects marked as to be deployed: $i/$($adf.AllObjects().Count)"
    $ToBeDeployedList | ForEach-Object {
        Write-Host "- $($_.FullName($true))"
    }

    if (!$TerraformStyle) {
        return $null
    }

    $plan = Get-DryRunPlan -adf $adf -targetAdfInstance $targetAdfInstance
    Write-DryRunPlan -plan $plan
    return $plan

}

function ConvertTo-CanonicalAdfType {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        [String] $Type
    )

    $t = $Type.ToLowerInvariant()
    switch ($t)
    {
        'pipeline' { return 'pipeline' }
        'dataset' { return 'dataset' }
        'dataflow' { return 'dataflow' }
        'linkedservice' { return 'linkedService' }
        'integrationruntime' { return 'integrationRuntime' }
        'trigger' { return 'trigger' }
        'factory' { return 'factory' }
        'managedvirtualnetwork' { return 'managedVirtualNetwork' }
        'managedprivateendpoint' { return 'managedPrivateEndpoint' }
        'credential' { return 'credential' }
        default { return $Type }
    }
}

function Get-AdfObjectFullName {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        $Object
    )

    $name = $Object.Name
    $simtype = ''

    if ($Object -is [AdfObject]) {
        $simtype = Get-SimplifiedType -Type $Object.Type
        if ($Object.Type -like 'Microsoft.DataFactory/factories*') {
            $simtype = ConvertTo-AdfType -AzType $Object.Type
            $simtype = Get-SimplifiedType -Type $simtype
        }
    }
    else {
        $simtype = Get-SimplifiedType -Type $Object.GetType().Name
    }

    $simtype = ConvertTo-CanonicalAdfType -Type $simtype
    return "$simtype.$name"
}

function Get-DryRunPlan {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adf,
        [parameter(Mandatory = $false)] $targetAdfInstance
    )

    $create = @()
    $update = @()
    $delete = @()
    $unchanged = @()

    $sourceByName = @{}
    $adf.AllObjects() | ForEach-Object {
        $fullName = Get-AdfObjectFullName -Object $_
        $sourceByName[$fullName] = $_
    }

    $targetByName = @{}
    if ($null -ne $targetAdfInstance) {
        $targetAdfInstance.AllObjects() | ForEach-Object {
            $fullName = Get-AdfObjectFullName -Object $_
            $targetByName[$fullName] = $_
        }
    }

    $adf.AllObjects() | ForEach-Object {
        $fullName = Get-AdfObjectFullName -Object $_
        if ($_.ToBeDeployed -eq $false) {
            $unchanged += $fullName
        }
        elseif ($targetByName.ContainsKey($fullName)) {
            $update += $fullName
        }
        else {
            $create += $fullName
        }
    }

    if ($null -ne $targetAdfInstance -and $adf.PublishOptions.DeleteNotInSource) {
        $targetByName.Keys | ForEach-Object {
            $fullName = $_
            if (!$sourceByName.ContainsKey($fullName)) {
                $oname = [AdfObjectName]::new($fullName)
                $canDelete = $true
                if ($adf.PublishOptions.DoNotDeleteExcludedObjects) {
                    $canDelete = !($oname.IsNameExcluded($adf.PublishOptions))
                }
                if ($canDelete) {
                    $delete += $fullName
                }
            }
        }
    }

    $create = @($create | Sort-Object)
    $update = @($update | Sort-Object)
    $delete = @($delete | Sort-Object)
    $unchanged = @($unchanged | Sort-Object)

    return [PSCustomObject]@{
        Create = @($create)
        Update = @($update)
        Delete = @($delete)
        Unchanged = @($unchanged)
    }
}

function Write-DryRunPlan {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        $plan
    )

    Write-Host "==================================================================================="
    Write-Host "Terraform-like plan (DryRun):"
    Write-Host "Plan: $($plan.Create.Count) to add, $($plan.Update.Count) to change, $($plan.Delete.Count) to destroy."

    if ($plan.Create.Count -gt 0) {
        Write-Host ""
        Write-Host "  + Create"
        $plan.Create | ForEach-Object { Write-Host "    + $_" }
    }

    if ($plan.Update.Count -gt 0) {
        Write-Host ""
        Write-Host "  ~ Update"
        $plan.Update | ForEach-Object { Write-Host "    ~ $_" }
    }

    if ($plan.Delete.Count -gt 0) {
        Write-Host ""
        Write-Host "  - Delete"
        $plan.Delete | ForEach-Object { Write-Host "    - $_" }
    }

    if ($plan.Unchanged.Count -gt 0) {
        Write-Host ""
        Write-Host "  = Unchanged / skipped"
        $plan.Unchanged | ForEach-Object { Write-Host "    = $_" }
    }

}