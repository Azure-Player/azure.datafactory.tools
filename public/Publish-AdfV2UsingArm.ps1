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
        
        [parameter(Mandatory = $false)] 
        [AdfPublishOption] $Option
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
    #Write-Host "Stage:              $Stage";
    Write-Host "Options provided:   $($null -ne $Option)";
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
    
    Write-Host "===================================================================================";
    Write-Host "STEP: Reading Azure Data Factory from ARM Template files..."
    $arm = Get-Content -Path $TemplateFile -Raw | ConvertFrom-Json 
    $armParam = Get-Content -Path $TemplateParameterFile -Raw | ConvertFrom-Json 
    
    $adf = New-Object -TypeName 'adf'
    $adf.Name = $armParam.parameters.factoryName.value
    $adf.ResourceGroupName = $ResourceGroupName

    # Apply Deployment Options if applicable
    if ($null -ne $Option) {
        #ApplyExclusionOptions -adf $adf
        Write-Warning 'Selective deployment is not supported for this method yet.'
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Replacing all properties environment-related..."
    Write-Warning 'Update parameters is not supported for this method yet.'
    # if (![string]::IsNullOrEmpty($Stage)) {
    #     #Update-PropertiesFromFile -adf $adf -stage $Stage
    # } else {
    #     Write-Host "Stage parameter was not provided - action skipped."
    # }

    Write-Host "===================================================================================";
    Write-Host "STEP: Stopping triggers..."
    if ($opt.StopStartTriggers -eq $true) {
        #Stop-Triggers -adf $adf
        Write-Warning 'The feature is not supported for this method yet.'
    } else {
        Write-Host "Operation skipped as publish option 'StopStartTriggers' = false"
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Deployment of ARM Template of ADF..."
    if ($opt.DeployGlobalParams -eq $false) {
        Write-Host "Deployment of Global Parameters will be skipped as publish option 'DeployGlobalParams' = false"
        # if ($adf.Factories.Count -gt 0) {
        #     $adf.Factories[0].ToBeDeployed = $false
        # }
        Write-Warning 'The feature is not supported for this method yet.'
    }

    $DataFactoryName = $armParam.parameters.factoryName.value
    $location = $armParam.parameters.dataFactory_location.value
    $t = (Get-Date).TOString('MMdd-HHmm')
    $DeploymentName = "DeployADF-$t"
    Write-Host "      Deployment name: $DeploymentName"
    New-AzResourceGroupDeployment -Name "$DeploymentName" -Mode 'Incremental' `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterFile $TemplateParameterFile

    Write-Host "===================================================================================";
    Write-Host "STEP: Deleting objects not in source ..."
    if ($opt.DeleteNotInSource -eq $true) {
        # $adfIns = Get-AdfFromService -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
        # $adfIns.AllObjects() | ForEach-Object {
        #     Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $_ -adfInstance $adfIns
        # }
        Write-Warning 'The feature is not supported for this method yet.'
    } else {
        Write-Host "Operation skipped as publish option 'DeleteNotInSource' = false"
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Starting all triggers..."
    if ($opt.StopStartTriggers -eq $true) {
        #Start-Triggers -adf $adf
        Write-Warning 'The feature is not supported for this method yet.'
    } else {
        Write-Host "Operation skipped as publish option 'StopStartTriggers' = false"
    }
    
    $elapsedTime = new-timespan $script:StartTime $(get-date)
    Write-Host "==============================================================================";
    Write-Host "   *****   Azure Data Factory files have been deployed successfully.   *****`n";
    Write-Host "Data Factory name:  $DataFactoryName";
    Write-Host "Region (Location):  $location";
    Write-Host ([string]::Format("     Elapsed time:  {0:d1}:{1:d2}:{2:d2}.{3:d3}`n", $elapsedTime.Hours, $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Milliseconds))
    Write-Host "==============================================================================";

    #return $adf
}
