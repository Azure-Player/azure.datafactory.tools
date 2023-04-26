# KN: These functions are currently not in use

function Get-GlobalParam([string]$ResourceGroupName, [string]$DataFactoryName)
{
  $azContext = Get-AzContext
  [string] $SubscriptionID = $azContext.Subscription.Id
  $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
  $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
  $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
  $authHeader = @{
      'Content-Type'='application/json'
      'Authorization'='Bearer ' + $token.AccessToken
  }

  $restUri = "https://management.azure.com/subscriptions/$SubscriptionID/resourcegroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$DataFactoryName/globalParameters/default?api-version=2018-06-01"
  $params = @{
      Headers = $authHeader
      Method = 'GET'
      Uri = $restUri
  }

  try {
    $response = Invoke-RestMethod @params
  }
  catch {
    Write-Error -Exception $_.Exception
  }
  return $response
}


function Set-GlobalParam([string]$ResourceGroupName, [string]$DataFactoryName, $value)
{
  $azContext = Get-AzContext
  [string] $SubscriptionID = $azContext.Subscription.Id
  $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
  $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
  $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
  $authHeader = @{
      'Content-Type'='application/json'
      'Authorization'='Bearer ' + $token.AccessToken
  }

  $body = "{
    ""properties"": { ""adftools_deployment_state"": { ""value"": ""$value AJHIUHWIUI"", ""type"": ""Object"" }  }
  }"

  $restUri = "https://management.azure.com/subscriptions/$SubscriptionID/resourcegroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$DataFactoryName/globalParameters/default?api-version=2018-06-01"
  $params = @{
      Headers = $authHeader
      Body = $body
      Method = 'PUT'
      Uri = $restUri
  }

  try {
    $response = Invoke-RestMethod @params
  }
  catch {
    Write-Error -Exception $_.Exception
  }
  return $response
}


