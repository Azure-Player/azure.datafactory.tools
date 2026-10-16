function Export-AdfToArmTemplate {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)] 
        [String] $RootFolder,
        [parameter(Mandatory = $false)] 
        [String] $SubscriptionId = 'ffff-ffff',
        [parameter(Mandatory = $false)] 
        [String] $ResourceGroup = 'abcxyz',
        [parameter(Mandatory = $false)] 
        [String] $AdfUtilitiesVersion = '1.0.2',
        [parameter(Mandatory = $false)] 
        [String] $OutputFolder = 'ArmTemplate'
    )

    Set-Location $RootFolder

    Write-Host "=== Preparing package.json file..."
    $packageJson = "{
        ""scripts"": {
            ""build"": ""node node_modules/@microsoft/azure-data-factory-utilities/lib/index""
        },
        ""dependencies"": {
            ""@microsoft/azure-data-factory-utilities"": ""^$AdfUtilitiesVersion""
        }
    }"
    Set-Content -Path "$RootFolder\package.json" -Value $packageJson -Force
    Write-Host "=== File 'package.json' created."

    # Validate and export ARM Template using @microsoft/azure-data-factory-utilities module
    Write-Host "=== Check NPM Version..."
    Invoke-AdfNpm -Arguments 'version'
    Write-Host "=== Check finished."

    Write-Host "=== Installing NPM azure-data-factory-utilities..."
    Invoke-AdfNpm -Arguments 'i', '@microsoft/azure-data-factory-utilities'
    Write-Host "=== Installation finished."

    $AdfName = Split-Path -Path $RootFolder -Leaf
    $adfAzurePath = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DataFactory/factories/$AdfName"

    Write-Host "=== Validating & exporting ARM Template..."
    Invoke-AdfNpm -Arguments 'run', 'build', 'export', $RootFolder, $adfAzurePath, $OutputFolder
    Write-Host "=== Export finished."

}
