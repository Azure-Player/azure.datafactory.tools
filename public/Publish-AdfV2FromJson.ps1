function Publish-AdfV2FromJson {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)] [String] $RootFolder,
        [parameter(Mandatory = $true)] [String] $ResourceGroupName,
        [parameter(Mandatory = $true)] [String] $DataFactoryName,
        [parameter(Mandatory = $false)] [String] $Stage = $null,
        [parameter(Mandatory = $false)] [String] $Location
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

    # STEP 1: Create ADF if not exists
    Write-Host "STEP 1: Verifying whether ADF exists..."
    $adf = Get-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName" -ErrorAction:Ignore
    if (!$adf) {
        Write-Host "Creating Azure Data Factory..."
        Set-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName" -Location "$Location"
    } else {
        Write-Host "Azure Data Factory exists."
    }

    $adf = Import-AdfFromFolder -FactoryName $DataFactoryName -RootFolder "$RootFolder"
    $adf.ResourceGroupName = "$ResourceGroupName";
    Write-Debug ($adf | Format-List | Out-String)

    # STEP 2
    Write-Host "===================================================================================";
    Write-Host "STEP 2: Replacing all properties environment-related..."
    if (![string]::IsNullOrEmpty($Stage)) {
        Update-PropertiesFromCsvFile -adf $adf -stage $Stage
    } else {
        Write-Host "Stage parameter was not provided - action skipped."
    }

    # STEP 3a
    Write-Host "===================================================================================";
    Write-Host "STEP 3a: Stopping triggers..."
    Stop-Triggers -adf $adf

    # STEP 3b
    Write-Host "===================================================================================";
    Write-Host "STEP 3b: Deployment of all ADF objects..."
    $adf.AllObjects() | ForEach-Object {
        Deploy-AdfObject -obj $_
    }

    # STEP 3c
    Write-Host "===================================================================================";
    Write-Host "STEP 3c: Starting all triggers..."
    Start-Triggers -adf $adf
    
    $elapsedTime = new-timespan $script:StartTime $(get-date)
    Write-Host "==============================================================================";
    Write-Host "       Azure Data Factory files have been deployed successfully.";
    Write-Host ([string]::Format("             Elapsed time: {0:d1}:{1:d2}:{2:d2}.{3:d3}", $elapsedTime.Hours, $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Milliseconds))
    Write-Host "==============================================================================";
}
