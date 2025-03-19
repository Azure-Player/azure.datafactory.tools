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

  $restUri = "$BaseApiUrl/subscriptions/$SubscriptionID/resourcegroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$DataFactoryName/globalParameters/default?api-version=2018-06-01"
  Write-Debug "Get-GlobalParam:Request preparing to URL: $restUri"

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
    $response = ""  # Workaround when ADF service returns error 404 for newly created ADF
  }
  return $response
}


function Set-GlobalParam([Adf] $adf)
{
  $ResourceGroupName = $adf.ResourceGroupName
  $DataFactoryName = $adf.Name

  $azContext = Get-AzContext
  [string] $SubscriptionID = $azContext.Subscription.Id
  $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
  $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
  $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
  $authHeader = @{
      'Content-Type'='application/json'
      'Authorization'='Bearer ' + $token.AccessToken
  }

  $gp = ($adf.GlobalFactory.body | ConvertFrom-Json).properties.globalParameters | ConvertTo-Json -Depth 50

  $body = "{
    ""properties"": $gp
  }"

  $restUri = "$BaseApiUrl/subscriptions/$SubscriptionID/resourcegroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$DataFactoryName/globalParameters/default?api-version=2018-06-01"
  Write-Debug "Set-GlobalParam:Request preparing to URL: $restUri"
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
    $response = ""
  }
  return $response
}


