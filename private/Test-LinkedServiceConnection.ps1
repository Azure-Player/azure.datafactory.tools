# Credits to: Simon D'Morias for his blog post:
# https://datathirst.net/blog/2018/9/23/adfv2-testing-linked-services


function Get-Bearer(
  [string] $TenantID, 
  [string] $ClientID, 
  [string] $ClientSecret
)
{
  $TokenEndpoint = {https://login.windows.net/{0}/oauth2/token} -f $TenantID 
  $ARMResource = "https://management.core.windows.net/";

  $Body = @{
          'resource'= $ARMResource
          'client_id' = $ClientID
          'grant_type' = 'client_credentials'
          'client_secret' = $ClientSecret
  }

  $request = @{
      ContentType = 'application/x-www-form-urlencoded'
      Headers = @{'accept'='application/json'}
      Body = $Body
      Method = 'Post'
      URI = $TokenEndpoint
  }

  $token = Invoke-RestMethod @request

  return "Bearer " + ($token.access_token).ToString()
}


function Get-LinkedServiceBody(
  [string] $LinkedServiceName, 
  [string] $DataFactoryName, 
  [string] $ResourceGroupName, 
  [string] $BearerToken, 
  [string] $SubscriptionID
)
{
  Write-Debug "BEGIN: Get-LinkedServiceBody()"
  $ADFEndpoint = "$BaseApiUrl/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$DataFactoryName/linkedservices/$($LinkedServiceName)?api-version=2018-06-01"
  Write-Debug "Get-LinkedServiceBody:Request preparing to URL: $ADFEndpoint"

  $request = @{
      ContentType = 'application/json'
      Headers = @{'accept'='application/json';'Authorization'=$BearerToken}
      Method = 'GET'
      URI = $ADFEndpoint
  }

  $a = Invoke-RestMethod @request
  Write-Debug "END: Get-LinkedServiceBody()"
  return ConvertTo-Json -InputObject @{"linkedService" = $a} -Depth 50
}

function Get-LinkedServiceBodyAzRestMethod(
  [string] $LinkedServiceName, 
  [string] $DataFactoryName, 
  [string] $ResourceGroupName, 
  [string] $SubscriptionID,
  $Params
)
{
  Write-Debug "BEGIN: Get-LinkedServiceBodyAzRestMethod()"

  $ADFEndpoint = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$DataFactoryName/linkedservices/$($LinkedServiceName)?api-version=2018-06-01"

  $request = @{
      Path = $ADFEndpoint
      Method = 'GET'
  }

  $a = Invoke-AzRestMethod @request
  $a = ($a.Content | ConvertFrom-Json)
  #Write-Debug (ConvertTo-Json -InputObject @{"linkedService" = $a} -Depth 50)
  Write-Debug "END: Get-LinkedServiceBodyAzRestMethod()"
  return ConvertTo-Json -InputObject @{"linkedService" = $a} -Depth 50
}


function Test-LinkedServiceConnection(
  [string] $LinkedServiceName,
  [string] $DataFactoryName,
  [string] $ResourceGroupName,
  [string] $BearerToken,
  [string] $SubscriptionID,
  $Params
)
{
  Write-Debug "BEGIN: Test-LinkedServiceConnection()"

  try {
    $body = Get-LinkedServiceBody -LinkedServiceName $LinkedServiceName -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -BearerToken $bearerToken -SubscriptionID $SubscriptionID

    $AzureEndpoint = "$BaseApiUrl/subscriptions/$SubscriptionID/resourcegroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$DataFactoryName/testConnectivity?api-version=2018-06-01"
    Write-Debug "Test-LinkedServiceConnection:Request preparing to URL: $AzureEndpoint"

    $body = Add-LinkedServiceTestParams -Body $body -Params $Params

    Write-Verbose '============== Linked Service to being connection tested ============='
    Write-Verbose $body
    Write-Verbose '======================================================================'

    $request = @{
        ContentType = 'application/json'
        Headers = @{'accept'='application/json';'Authorization'=$BearerToken}
        Body = $Body
        Method = 'POST'
        Uri = $AzureEndpoint
    }

    $response = Invoke-RestMethod @request -ErrorAction Stop
  }
  catch {
    # A failed call (e.g. linked service not found) is a failed test of this linked service, not an error stopping the other tests
    $response = New-LinkedServiceTestFailure -Message $_.Exception.Message
  }
  Write-Debug "END: Test-LinkedServiceConnection()"
  return $response
}

function Test-LinkedServiceConnectionAzRestMethod(
  [string] $LinkedServiceName,
  [string] $DataFactoryName,
  [string] $ResourceGroupName,
  [string] $SubscriptionID,
  $Params
)
{
  Write-Debug "BEGIN: Test-LinkedServiceConnectionAzRestMethod()"

  try {
    $body = Get-LinkedServiceBodyAzRestMethod -LinkedServiceName $LinkedServiceName -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -SubscriptionID $SubscriptionID
    $ls = ($body | ConvertFrom-Json).linkedService
    if ($null -ne $ls -and $ls.PSObject.Properties['error']) {
      # Linked service could not be read (e.g. not found): return the API error
      Write-Debug "END: Test-LinkedServiceConnectionAzRestMethod()"
      return $ls
    }

    $AzureEndpoint = "/subscriptions/$SubscriptionID/resourcegroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$DataFactoryName/testConnectivity?api-version=2018-06-01"

    $body = Add-LinkedServiceTestParams -Body $body -Params $Params

    $request = @{
        Path = $AzureEndpoint
        Payload = $Body
        Method = 'POST'
    }

    # Invoke-AzRestMethod does not throw on HTTP errors: the error response (e.g. {"error":{...}}) is returned as content
    $response = Invoke-AzRestMethod @request -ErrorAction Stop
    $result = $response.Content | ConvertFrom-Json
  }
  catch {
    # A failed call is a failed test of this linked service, not an error stopping the other tests
    $result = New-LinkedServiceTestFailure -Message $_.Exception.Message
  }
  Write-Debug "END: Test-LinkedServiceConnectionAzRestMethod()"
  return $result
}

function Add-LinkedServiceTestParams(
  [string] $Body,
  $Params
)
{
  if (-not $Params) { return $Body }
  Write-Verbose "Found input parameters for this Linked Service, adding to the API request..."
  $j = ConvertFrom-Json $Body
  # Linked service may have no 'parameters' property yet (strict mode)
  $j.linkedService.properties | Add-Member -NotePropertyName 'parameters' -NotePropertyValue $Params -Force
  return (ConvertTo-Json -InputObject $j -Depth 50)
}


function New-LinkedServiceTestFailure(
  [string] $Message
)
{
  return [PSCustomObject]@{ succeeded = $false; error = [PSCustomObject]@{ code = ''; message = $Message } }
}

function Get-LinkedServiceTestError(
  $Response
)
{
  # Failed connection test: {"succeeded":false,"errors":[{"code":..,"message":..}]}; API error: {"error":{"code":..,"message":..}}
  if ($null -eq $Response) { return 'No response from the API.' }
  $items = @()
  if ($Response.PSObject.Properties['errors']) { $items = @($Response.errors) }
  elseif ($Response.PSObject.Properties['error']) { $items = @($Response.error) }
  $messages = @($items | Where-Object { $null -ne $_ } | ForEach-Object {
    $code = if ($_.PSObject.Properties['code']) { "$($_.code)" } else { '' }
    $message = if ($_.PSObject.Properties['message']) { "$($_.message)" } else { ($_ | ConvertTo-Json -Depth 5 -Compress) }
    if ($code -ne '') { "$($code): $message" } else { $message }
  })
  return ($messages -join ' | ')
}
