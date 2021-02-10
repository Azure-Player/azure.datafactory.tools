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
        [parameter(Mandatory = $true)] 
        [String] $TenantID,
        [parameter(Mandatory = $true)] 
        [String] $ClientID,
        [parameter(Mandatory = $true)] 
        [String] $ClientSecret
    )

    $bearerToken = Get-Bearer -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret

    $all = 0
    $ok = 0
    $LinkedServiceName.Split(',') | ForEach-Object { 
        $all += 1
        $ls = $_
        Write-Host "Testing ADF Linked Service connection: [$_] ..." 
        $r = Test-LinkedServiceConnection -LinkedServiceName $ls -DataFactoryName $DataFactoryName -ResourceGroup $ResourceGroupName -BearerToken $bearerToken
        if ($null -ne $r -and $r.succeeded) {
            Write-Host "[$_] : Connection successful."
            $ok += 1
        } else {
            Write-Host "[$_] : Connection failed."
        }
    }
    
    Write-Host "Test connection result:"
    Write-Host "Passed: $ok"
    Write-Host "Failed: $($all-$ok)"
    Write-Host "Total : $all"

}

