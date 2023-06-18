function Test-AdfLinkedService {
    [CmdletBinding(DefaultParameterSetName = 'AzRestMethod')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'AzRestMethod')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientDetails')]
        [String] $LinkedServiceName,

        [Parameter(Mandatory = $true, ParameterSetName = 'AzRestMethod')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientDetails')]
        [String] $DataFactoryName,

        [Parameter(Mandatory = $true, ParameterSetName = 'AzRestMethod')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientDetails')]
        [String] $ResourceGroupName,

        [Parameter(Mandatory = $true, ParameterSetName = 'AzRestMethod')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientDetails')]
        [String] $SubscriptionID,

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientDetails')]
        [String] $TenantID,

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientDetails')]
        [String] $ClientID,

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientDetails')]
        [String] $ClientSecret
    )
    Write-Debug "BEGIN: Test-AdfLinkedService(ParameterSetName = $($PSCmdlet.ParameterSetName))"

    if ($PSCmdlet.ParameterSetName -eq "ClientDetails") {
        $bearerToken = Get-Bearer -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret
    }
    $defFile = $false
    if ($LinkedServiceName.EndsWith('.json'))
    {
        Write-Host "Definition of Linked Services in json file: $LinkedServiceName"
        $definitionFile = Get-Content -Path $LinkedServiceName -Encoding utf8 -Raw
        $j = $definitionFile | ConvertFrom-Json
        $list = $j.linkedServices
        Write-Host "Found $($list.Count) name(s) in definition file."
        $defFile = $true
    }
    else {
        $list = $LinkedServiceName.Split(',')
        Write-Host "Found $($list.Count) name(s) in comma-separated list."
    }

    $report = @{}
    $all = 0
    $ok = 0
    $list | ForEach-Object { 
        $all += 1
        if ($defFile) { 
            $ls = $_.name 
            $params = $_.parameters
        } 
        else 
        { 
            $ls = $_ 
            $params = $null
        }
        Write-Host "Testing ADF Linked Service connection: [$ls] ..." 
        if ($PSCmdlet.ParameterSetName -eq "ClientDetails") {
            $r = Test-LinkedServiceConnection -LinkedServiceName $ls `
                -DataFactoryName $DataFactoryName `
                -ResourceGroup $ResourceGroupName `
                -BearerToken $bearerToken `
                -SubscriptionID $SubscriptionID `
                -Params $params
        } else {
            $r = Test-LinkedServiceConnectionAzRestMethod -LinkedServiceName $ls `
                -DataFactoryName $DataFactoryName `
                -ResourceGroup $ResourceGroupName `
                -SubscriptionID $SubscriptionID `
                -Params $params
        }
        $id = [String]::Format("{0:000}) {1}", $all, $ls)
        if ($null -ne $r -and $r.succeeded) {
            Write-Host "$all) [$ls] : Connection successful."
            $report.Add($id, $true)
            $ok += 1
        } else {
            Write-Host "$all) [$ls] : Connection failed."
            $report.Add($id, $false)
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

