# Credits to: Simon D'Morias for his blog post:
# https://datathirst.net/blog/2018/9/23/adfv2-testing-linked-services


function Get-Bearer([string]$TenantID, [string]$ClientID, [string]$ClientSecret)
{
  $TokenEndpoint = {https://login.windows.net/{0}/oauth2/token} -f $TenantID 
  $ARMResource = "https://management.core.windows.net/";

  $Body = @{
          'resource'= $ARMResource
          'client_id' = $ClientID
          'grant_type' = 'client_credentials'
          'client_secret' = $ClientSecret
  }

  $params = @{
      ContentType = 'application/x-www-form-urlencoded'
      Headers = @{'accept'='application/json'}
      Body = $Body
      Method = 'Post'
      URI = $TokenEndpoint
  }

  $token = Invoke-RestMethod @params

  return "Bearer " + ($token.access_token).ToString()
}


function Get-LinkedServiceBody([string]$LinkedServiceName, [string]$DataFactoryName, [string]$ResourceGroupName, [string]$BearerToken)
{
  $ADFEndpoint = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$DataFactoryName/linkedservices/$($LinkedServiceName)?api-version=2018-06-01"

  $params = @{
      ContentType = 'application/json'
      Headers = @{'accept'='application/json';'Authorization'=$BearerToken}
      Method = 'GET'
      URI = $ADFEndpoint
  }

  $a = Invoke-RestMethod @params
  return ConvertTo-Json -InputObject @{"linkedService" = $a} -Depth 50
}


function Test-LinkedServiceConnection([string]$LinkedServiceName, [string]$DataFactoryName, [string]$ResourceGroupName, [string]$BearerToken)
{

  $body = Get-LinkedServiceBody -LinkedServiceName $LinkedServiceName -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -BearerToken $bearerToken

  $AzureEndpoint = "https://management.azure.com/subscriptions/$SubscriptionID/resourcegroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$DataFactoryName/testConnectivity?api-version=2018-06-01"

  $params = @{
      ContentType = 'application/json'
      Headers = @{'accept'='application/json';'Authorization'=$BearerToken}
      Body = $Body
      Method = 'Post'
      Uri = $AzureEndpoint
  }

  try {
    $response = Invoke-RestMethod @params
  }
  catch {
    Write-Error -Exception $_.Exception
  }
  return $response
}
