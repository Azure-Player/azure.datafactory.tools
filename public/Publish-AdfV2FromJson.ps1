function Publish-AdfV2FromJson {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)] [String] $RootFolder,
        [parameter(Mandatory = $true)] [String] $ResourceGroupName,
        [parameter(Mandatory = $true)] [String] $DataFactoryName,
        [parameter(Mandatory = $false)] [String] $Stage = $null
    )

    Write-Host "===================================================================================";
    Write-Host "### azure.datafactory.tools                                Version 0.2.000 ###";
    Write-Host "===================================================================================";
    Write-Host "Invoking Publish-AdfV2FromJson (https://github.com/KamilNowinski/DeployAdfFromJson)";
    Write-Host "with the following parameters:";
    Write-Host "===================================================================================";
    Write-Host "RootFolder:         $RootFolder";
    Write-Host "ResourceGroupName:  $ResourceGroupName";
    Write-Host "DataFactoryName:    $DataFactoryName";
    Write-Host "Stage:              $stage";
    Write-Host "===================================================================================";

    # STEP 1: Create ADF if not exists
    Write-Host "STEP 1: Verifying whether ADF exists..."
    $adf = Get-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName" -ErrorAction:Ignore
    if (!$adf) {
        Write-Host "Creating Azure Data Factory..."
        New-AzDataFactoryV2 -ResourceGroupName "$ResourceGroupName" -Name "$DataFactoryName" 
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

    # STEP 3
    Write-Host "===================================================================================";
    Write-Host "STEP 3: Deployment of all ADF objects..."
    $adf.AllObjects() | ForEach-Object {
        Deploy-AdfObject -obj $_
    }

    Write-Host "==============================================================================";
    Write-Host "       Azure Data Factory files have been deployed successfully.";
    Write-Host "==============================================================================";
}
