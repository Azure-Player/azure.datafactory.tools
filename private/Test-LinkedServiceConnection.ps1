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

  $body = Get-LinkedServiceBody -LinkedServiceName $LinkedServiceName -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -BearerToken $bearerToken -SubscriptionID $SubscriptionID

  $AzureEndpoint = "$BaseApiUrl/subscriptions/$SubscriptionID/resourcegroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$DataFactoryName/testConnectivity?api-version=2018-06-01"
  Write-Debug "Test-LinkedServiceConnection:Request preparing to URL: $AzureEndpoint"

  if ($Params) {
    Write-Verbose "Found input parameters for this Linked Service, adding to the API request..."
    $j = ConvertFrom-Json $body 
    $j.linkedService.properties.parameters = $Params
    $body = ConvertTo-Json -InputObject $j -Depth 50
  }

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

  try {
    $response = Invoke-RestMethod @request
  }
  catch {
    Write-Error -Exception $_.Exception
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

  $body = Get-LinkedServiceBodyAzRestMethod -LinkedServiceName $LinkedServiceName -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -SubscriptionID $SubscriptionID

  $AzureEndpoint = "/subscriptions/$SubscriptionID/resourcegroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$DataFactoryName/testConnectivity?api-version=2018-06-01"

  if ($Params) {
    Write-Verbose "Found input parameters for this Linked Service, adding to the API request..."
    $j = ConvertFrom-Json $body 
    $j.linkedService.properties.parameters = $Params
    $body = ConvertTo-Json -InputObject $j -Depth 50
  }

  $request = @{
      Path = $AzureEndpoint
      Payload = $Body
      Method = 'POST'
  }

  try {
    $response = Invoke-AzRestMethod @request
  }
  catch {
    # Note: Invoke-AzRestMethod fails when payload indicates failure and error will be printed. Not fully feature parity with LinkedServiceConnection
    Write-Error -Exception $_.Exception
  }
  Write-Debug "END: Test-LinkedServiceConnectionAzRestMethod()"
  return ($response.Content | ConvertFrom-Json)
}
