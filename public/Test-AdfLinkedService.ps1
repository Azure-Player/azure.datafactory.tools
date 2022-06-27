function Test-AdfLinkedService {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] 
        [String] $LinkedServiceName,
        [parameter(Mandatory = $true)] 
        [String] $DataFactoryName,
        [parameter(Mandatory = $true)] 
        [String] $ResourceGroupName,
        [parameter(Mandatory = $true)] 
        [String] $SubscriptionID,
        [parameter(Mandatory = $true, ParameterSetName="ClientDetails")] 
        [String] $TenantID,
        [parameter(Mandatory = $true, ParameterSetName="ClientDetails")] 
        [String] $ClientID,
        [parameter(Mandatory = $true, ParameterSetName="ClientDetails")] 
        [String] $ClientSecret,
        [parameter(Mandatory = $true, ParameterSetName="AzRestMethod")]
        [switch] $preferAzRestMethod
    )

    if ($PSCmdlet.ParameterSetName -eq "ClientDetails") {
        $bearerToken = Get-Bearer -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret
    }

    $all = 0
    $ok = 0
    $LinkedServiceName.Split(',') | ForEach-Object { 
        $all += 1
        $ls = $_
        Write-Host "Testing ADF Linked Service connection: [$_] ..." 
        if ($PSCmdlet.ParameterSetName -eq "ClientDetails") {
            $r = Test-LinkedServiceConnection -LinkedServiceName $ls -DataFactoryName $DataFactoryName -ResourceGroup $ResourceGroupName -BearerToken $bearerToken -SubscriptionID $SubscriptionID
        } else {
            $r = Test-LinkedServiceConnectionAzRestMethod -LinkedServiceName $ls -DataFactoryName $DataFactoryName -ResourceGroup $ResourceGroupName -SubscriptionID $SubscriptionID
            Write-Debug ($r | ConvertTo-Json)
        }
        if ($null -ne $r -and $r.succeeded) {
            Write-Host "[$_] : Connection successful."
            $ok += 1
        } else {
            Write-Host ($r | ConvertTo-Json)
            Write-Host "[$_] : Connection failed."
        }
    }
    
    Write-Host "Test connection result:"
    Write-Host "Passed: $ok"
    Write-Host "Failed: $($all-$ok)"
    Write-Host "Total : $all"

}

