<#
.SYNOPSIS
Publishes Azure Data Factory from ARM Template files into target ADF service.

.DESCRIPTION
Publishes Azure Data Factory from ARM Template files into target ADF service.
Additionaly, creates a data factory with the specified resource group name and location, if that doesn't exist.
Uses standard New-AzResourceGroupDeployment method in order to create new deployment in a given Resource Group.

.PARAMETER TemplateFile
Path to ARM template file

.PARAMETER TemplateParameterFile
Path to ARM template parameter file

.PARAMETER ResourceGroupName
Resource Group Name of target instance of ADF

.PARAMETER DataFactoryName
Name of target ADF instance

.PARAMETER Location
Azure Region for target ADF. Used only for create new ADF instance.

.PARAMETER Option
This objects allows to define certain behaviour of deployment process. Use cmdlet "New-AdfPublishOption" to create new instance of the object and set required properties.

.PARAMETER WhatIf


.EXAMPLE
$RootFolder = '.\BigFactorySample2'
$ArmFile = "$RootFolder\ArmTemplate\ARMTemplateForFactory.json"
$ArmParamFile = "$RootFolder\ArmTemplate\ARMTemplateParametersForFactory.json"
$rg = 'rg-devops-factory'
$location = 'northeurope'
$DataFactoryName = 'BigFactorySample2-test'
$o = New-AdfPublishOption
$o.StopStartTriggers = $false
Publish-AdfV2UsingArm -TemplateFile $ArmFile -TemplateParameterFile $ArmParamFile `
    -ResourceGroupName $rg -Location $location -Option $o `
    -DataFactory $DataFactoryName

.LINK
Online version: https://github.com/SQLPlayer/azure.datafactory.tools/
#>

function Publish-AdfV2UsingArm {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)] 
        [String] $TemplateFile,

        [parameter(Mandatory = $true)] 
        [String] $TemplateParameterFile,
        
        [parameter(Mandatory = $true)] 
        [String] $ResourceGroupName,

        [parameter(Mandatory = $true)] 
        [String] $DataFactoryName,

        [parameter(Mandatory = $false)] 
        [String] $Stage = $null,
        
        [parameter(Mandatory = $false)] 
        [String] $Location,

        [parameter(Mandatory = $false)] 
        [AdfPublishOption] $Option,

        [switch] $WhatIf = $false
    )

    $m = Get-Module -Name "azure.datafactory.tools"
    $verStr = $m.Version.ToString(2) + "." + $m.Version.Build.ToString("000");
    Write-Host "======================================================================================";
    Write-Host "### azure.datafactory.tools                                       Version $verStr ###";
    Write-Host "======================================================================================";
    Write-Host "Invoking Publish-AdfV2UsingArm  (https://github.com/SQLPlayer/azure.datafactory.tools)";
    Write-Host "with the following parameters:";
    Write-Host "======================================================================================";
    Write-Host "TemplateFile:          $TemplateFile";
    Write-Host "TemplateParameterFile: $TemplateParameterFile";
    Write-Host "ResourceGroupName:     $ResourceGroupName";
    Write-Host "DataFactoryName:       $DataFactoryName";
    Write-Host "Location:              $Location";
    #Write-Host "Stage:              $Stage";
    Write-Host "Options provided:      $($null -ne $Option)";
    Write-Host "WhatIfPreference:      $WhatIfPreference";
    Write-Host "======================================================================================";

    $script:StartTime = Get-Date

    if ($null -ne $Option) {
        Write-Host "Publish options are provided."
        $opt = $Option
    }
    else {
        Write-Host "Publish options are not provided."
        $opt = New-AdfPublishOption
    }

    if (!$WhatIfPreference) {
        Write-Host "STEP: Verifying whether ADF exists..."

        $targetAdf = Get-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName" -ErrorAction:Ignore
        if ($targetAdf) {
            Write-Host "Azure Data Factory exists."
        }
        else {
            $msg = "Azure Data Factory instance does not exist."
            if ($opt.CreateNewInstance) {
                Write-Host "$msg"
                Write-Host "Creating a new instance of Azure Data Factory..."
                $targetAdf = Set-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName" -Location "$Location"
                $targetAdf | Format-List | Out-String
            }
            else {
                Write-Host "Creation operation skipped as publish option 'CreateNewInstance' = false"
                Write-Error "ADFT0027: $msg"
            }
        }

        if ($null -eq $targetAdf) {
            Write-Host "ADFT0032: The process is exiting the function. Do fix the issue and run again."
            return 
        }
    }
    else {
        Write-Host "DRY RUN: Skipping ADF existence verification..."
    }
    
    Write-Host "===================================================================================";
    Write-Host "STEP: Reading Azure Data Factory from ARM Template files..."
    $adf = New-Object -TypeName 'adf'
    $adf.Location = Split-Path $TemplateFile -Parent
    $arm = Get-Content -Path $TemplateFile -Raw | ConvertFrom-Json 
    $armParamBody = Get-Content -Path $TemplateParameterFile -Raw
    $armParam = $armParamBody | ConvertFrom-Json
    $adf.ArmTemplateJson = $arm

    $arm.resources | ForEach-Object {
        $ArmType = $_.type
        $ArmName = $_.name
        $o = New-Object -TypeName 'AdfObject'
        $o.name = $ArmName.ToString().Substring(37, $ArmName.ToString().Length - 40)
        $o.type = ConvertTo-AdfType $ArmType
        $o.Adf = $adf
        $o.Body = $_
        $adf.Pipelines.Add($o)
        $collectionName = $ArmType.Substring(32)
        Invoke-Expression "`$adf.$collectionName.Add(`$o)"
    }
    if ($armParam.parameters.factoryName.value -ne $DataFactoryName) {
        Write-Error "Given factory name does not match name in ARMTemplate parameter file. The deployment stopped."
        return
    }
    $adf.Name = $DataFactoryName
    $adf.ResourceGroupName = $ResourceGroupName
    $adf.Region = $location
    $folder = Split-Path -Path $TemplateFile -Parent

    # Apply Deployment Options if applicable
    if ($null -ne $Option) {
        #ApplyExclusionOptions -adf $adf
        Write-Warning 'Selective deployment is not supported for this method yet.'
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Replacing all properties environment-related..."
    #Write-Warning 'Update parameters is not supported for this method yet.'
    if (![string]::IsNullOrEmpty($Stage)) {
        Update-PropertiesFromFile -adf $adf -stage $Stage

        #TODO: Remove 'never used' parameters from new ARM Template

        # Create new ARM Template file
        $OldTemplateFile = $TemplateFile
        $TemplateFile = $OldTemplateFile + '.~.json'
        Write-Verbose "Writing new ARM Template file: $TemplateFile"
        $output = ($adf.ArmTemplateJson | ConvertTo-Json -Compress:$true -Depth 100)
        $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
        [IO.File]::WriteAllLines($TemplateFile, $output, $Utf8NoBomEncoding)
    } else {
        Write-Host "Stage parameter was not provided - action skipped."
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Microsoft PreDeployment script..."
    if ($opt.StopStartTriggers -eq $true -and !$WhatIf) {
        #Stop-Triggers -adf $adf
        $script = Join-Path -Path $folder -ChildPath 'PrePostDeploymentScript.ps1'
        Write-Verbose "Running script: $script"
        . $script -armTemplate $TemplateFile -resourceGroupName $ResourceGroupName -dataFactoryName $DataFactoryName -predeployment $true
    } else {
        Write-Host "Operation skipped as WhatIf is enabled or publish option 'StopStartTriggers' = false"
    }


    Write-Host "===================================================================================";
    Write-Host "STEP: Deployment of ARM Template of ADF..."
    #$armParam = Get-Content -Path $TemplateParameterFile | ConvertFrom-Json #-AsHashtable
    #$t = (Get-Date).TOString('ddMM-HHmm')
    $DeploymentName = "ADFtools.deploy.$DataFactoryName"
    Write-Host "      Deployment name: $DeploymentName"

    if (!$WhatIf) {
        New-AzResourceGroupDeployment -Name "$DeploymentName" -Mode 'Incremental' `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterFile $TemplateParameterFile
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Deployment of Global Parameters..."
    if ($opt.DeployGlobalParams -eq $true -and !$WhatIf) {
        Write-Verbose "Source folder for global params and script: $folder"
        #$script = Join-Path -Path $folder -ChildPath 'GlobalParametersUpdateScript.ps1'
        $globjson = (Get-ChildItem -Path $folder -Filter '*_GlobalParameters.json')[0]
        Write-Verbose "Global Param file: $($globjson.FullName)"
        #. $script -globalParametersFilePath $globjson.FullName -resourceGroupName $ResourceGroupName -dataFactoryName $DataFactoryName
        Microsoft-GlobalParametersUpdateScript -globalParametersFilePath $globjson.FullName -resourceGroupName $ResourceGroupName -dataFactoryName $DataFactoryName
    } else {
        Write-Host "Deployment of Global Parameters will be skipped as WhatIf is enabled or publish option 'DeployGlobalParams' = false"
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Microsoft PostDeployment script:"
    Write-Host "      Deleting objects not in source = $($opt.DeleteNotInSource)"
    Write-Host "      Starting triggers = $($opt.StopStartTriggers)"
    if (($opt.StopStartTriggers -eq $true -or $opt.DeleteNotInSource -eq $true) -and !$WhatIf) {
        #Start-Triggers -adf $adf
        #$script = Join-Path -Path $folder -ChildPath 'PrePostDeploymentScript.ps1'
        #Write-Verbose "Running script: $script"
        #. $script -armTemplate $TemplateFile -resourceGroupName $ResourceGroupName -dataFactoryName $DataFactoryName -predeployment $false
        Microsoft-PrePostDeploymentScript -armTemplate $TemplateFile `
            -resourceGroupName $ResourceGroupName `
            -dataFactoryName $DataFactoryName `
            -predeployment $false `
            -DeleteNotInSource $opt.DeleteNotInSource `
            -StartActiveTriggers $opt.StopStartTriggers
    } else {
        Write-Host "Operation skipped as WhatIf is enabled or publish option 'StopStartTriggers' or 'DeleteNotInSource' = false"
    }
    
    $elapsedTime = new-timespan $script:StartTime $(get-date)
    Write-Host "==============================================================================";
    Write-Host "   *****   Azure Data Factory files have been deployed successfully.   *****`n";
    Write-Host "Data Factory name:  $DataFactoryName";
    Write-Host "Region (Location):  $location";
    Write-Host ([string]::Format("     Elapsed time:  {0:d1}:{1:d2}:{2:d2}.{3:d3}`n", $elapsedTime.Hours, $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Milliseconds))
    Write-Host "==============================================================================";

    return $adf
}
