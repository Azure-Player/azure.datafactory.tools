function Test-AdfLinkedService {
    [CmdletBinding(DefaultParameterSetName="AzRestMethod")]
    param (
        [Parameter(Mandatory = $true)] 
        [String] $LinkedServiceName,
        [Parameter(Mandatory = $true)] 
        [String] $DataFactoryName,
        [Parameter(Mandatory = $true)] 
        [String] $ResourceGroupName,
        [Parameter(Mandatory = $true)] 
        [String] $SubscriptionID,
        [Parameter(Mandatory = $true, ParameterSetName="ClientDetails")]
        [String] $TenantID,
        [Parameter(Mandatory = $true, ParameterSetName="ClientDetails")]
        [String] $ClientID,
        [Parameter(Mandatory = $true, ParameterSetName="ClientDetails")]
        [String] $ClientSecret
    )
    Write-Debug "BEGIN: Test-AdfLinkedService(ParameterSetName = $($PSCmdlet.ParameterSetName))"

    if ($PSCmdlet.ParameterSetName -eq "ClientDetails") {
        $bearerToken = Get-Bearer -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret
    }

    $report = @{}

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
        }
        if ($null -ne $r -and $r.succeeded) {
            Write-Host "[$_] : Connection successful."
            $report.Add($_, $true)
            $ok += 1
        } else {
            Write-Host "[$_] : Connection failed."
            $report.Add($_, $false)
            Write-Verbose ($r | ConvertTo-Json)
        }
    }
    
    Write-Host "Test connection result:"
    Write-Host "Passed: $ok"
    Write-Host "Failed: $($all-$ok)"
    Write-Host "Total : $all"

    Write-Debug "END: Test-AdfLinkedService()"
    $result = [ordered]@{Passed = $ok; Failed = ($all-$ok); Total = $all; Report = $report}
    return $result
}

