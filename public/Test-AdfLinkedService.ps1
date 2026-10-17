function Test-AdfLinkedService {
    [CmdletBinding(DefaultParameterSetName = 'AzRestMethod')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'AzRestMethod')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientDetails')]
        [String[]] $LinkedServiceName,

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
    # Each item is a json definition file or a (comma-separated list of) linked service name(s)
    $list = @(foreach ($item in $LinkedServiceName) {
        if ($item.EndsWith('.json'))
        {
            Write-Host "Definition of Linked Services in json file: $item"
            $definitionFile = Get-Content -Path $item -Encoding utf8 -Raw
            $j = $definitionFile | ConvertFrom-Json
            $defs = @($j.linkedServices)
            Write-Host "Found $($defs.Count) name(s) in definition file."
            foreach ($d in $defs) {
                $params = if ($d.PSObject.Properties['parameters']) { $d.parameters } else { $null }
                [PSCustomObject]@{ Name = ([String]$d.name).Trim(); Params = $params }
            }
        }
        else {
            $names = @($item.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
            Write-Host "Found $($names.Count) name(s) in comma-separated list."
            foreach ($n in $names) {
                [PSCustomObject]@{ Name = $n; Params = $null }
            }
        }
    })

    $report = @{}
    $errors = @{}
    $all = 0
    $ok = 0
    $list | ForEach-Object {
        $all += 1
        $ls = $_.Name
        $params = $_.Params
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
        # An error response (e.g. linked service not found) has no 'succeeded' property
        $succeeded = $false
        if ($r -is [System.Collections.IDictionary]) { $succeeded = ($r['succeeded'] -eq $true) }
        elseif ($null -ne $r -and $r.PSObject.Properties['succeeded']) { $succeeded = ($r.succeeded -eq $true) }
        if ($succeeded) {
            Write-Host "$all) [$ls] : Connection successful."
            $report.Add($id, $true)
            $ok += 1
        } else {
            $msg = Get-LinkedServiceTestError -Response $r
            Write-Host "$all) [$ls] : Connection failed. $msg"
            $report.Add($id, $false)
            $errors.Add($id, $msg)
            Write-Verbose ($r | ConvertTo-Json -Depth 10)
        }
    }

    Write-Host "Test connection result:"
    Write-Host "Passed: $ok"
    Write-Host "Failed: $($all-$ok)"
    Write-Host "Total : $all"

    Write-Debug "END: Test-AdfLinkedService()"
    $result = [ordered]@{Passed = $ok; Failed = ($all-$ok); Total = $all; Report = $report; Errors = $errors}
    return $result
}

