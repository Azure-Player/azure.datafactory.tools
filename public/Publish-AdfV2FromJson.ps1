function Publish-AdfV2FromJson {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)] [String] $RootFolder,
        [parameter(Mandatory = $true)] [String] $ResourceGroupName,
        [parameter(Mandatory = $true)] [String] $DataFactoryName,
        [parameter(Mandatory = $false)] [String] $Stage = $null,
        [parameter(Mandatory = $false)] [String] $Location,
        [parameter(Mandatory = $false)] [AdfPublishOption] $Option
    )

    $m = Get-Module -Name "azure.datafactory.tools"
    $verStr = $m.Version.ToString(2) + "." + $m.Version.Build.ToString("000");
    Write-Host "======================================================================================";
    Write-Host "### azure.datafactory.tools                                       Version $verStr ###";
    Write-Host "======================================================================================";
    Write-Host "Invoking Publish-AdfV2FromJson (https://github.com/SQLPlayer/azure.datafactory.tools)";
    Write-Host "with the following parameters:";
    Write-Host "======================================================================================";
    Write-Host "RootFolder:         $RootFolder";
    Write-Host "ResourceGroupName:  $ResourceGroupName";
    Write-Host "DataFactoryName:    $DataFactoryName";
    Write-Host "Location:           $Location";
    Write-Host "Stage:              $Stage";
    Write-Host "======================================================================================";

    $script:StartTime = Get-Date

    Write-Host "STEP: Verifying whether ADF exists..."
    $adf = Get-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName" -ErrorAction:Ignore
    if (!$adf) {
        Write-Host "Creating Azure Data Factory..."
        Set-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName" -Location "$Location"
    } else {
        Write-Host "Azure Data Factory exists."
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Reading Azure Data Factory from JSON files..."
    $adf = Import-AdfFromFolder -FactoryName $DataFactoryName -RootFolder "$RootFolder"
    $adf.ResourceGroupName = "$ResourceGroupName";
    Write-Debug ($adf | Format-List | Out-String)

    # Apply Deployment Options if applicable
    if ($null -ne $Option) {
        Write-Host "Publish options are provided."
        ApplyExclusionOptions -adf $adf -option $Option
        $opt = $Option
    }
    else {
        Write-Host "Publish options are not provided."
        $opt = New-AdfPublishOption
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Replacing all properties environment-related..."
    if (![string]::IsNullOrEmpty($Stage)) {
        Update-PropertiesFromCsvFile -adf $adf -stage $Stage
    } else {
        Write-Host "Stage parameter was not provided - action skipped."
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Stopping triggers..."
    if ($opt.StopStartTriggers -eq $true) {
        Stop-Triggers -adf $adf
    } else {
        Write-Host "Operation skipped as publish option 'StopStartTriggers' = false"
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Deployment of all ADF objects..."
    $adf.AllObjects() | ForEach-Object {
        Deploy-AdfObject -obj $_
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Deleting objects not in source ..."
    if ($opt.DeleteNotInSource -eq $true) {
        $adfIns = Get-AdfFromService -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
        $adfIns.AllObjects() | ForEach-Object {
            Remove-AdfObjectIfNotInSource -adfSource $adf -adfTargetObj $_ -adfInstance $adfIns
        }
    } else {
        Write-Host "Operation skipped as publish option 'DeleteNotInSource' = false"
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Starting all triggers..."
    if ($opt.StopStartTriggers -eq $true) {
        Start-Triggers -adf $adf
    } else {
        Write-Host "Operation skipped as publish option 'StopStartTriggers' = false"
    }
    
    $elapsedTime = new-timespan $script:StartTime $(get-date)
    Write-Host "==============================================================================";
    Write-Host "       Azure Data Factory files have been deployed successfully.";
    Write-Host ([string]::Format("             Elapsed time: {0:d1}:{1:d2}:{2:d2}.{3:d3}", $elapsedTime.Hours, $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Milliseconds))
    Write-Host "==============================================================================";
}
