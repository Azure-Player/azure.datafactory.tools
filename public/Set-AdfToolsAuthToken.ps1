<#
.SYNOPSIS
   Sets the tool's URL of base API. Default is "https://management.azure.com"

.DESCRIPTION
   Sets the tool's URL of base API. Default is "https://management.azure.com".
   Currently function accepts only one parameter, apiUrl, which is the URL of the Azure cloud.
   In the future, the function will accept additional parameters to aquire the authentication token.

.PARAMETER apiUrl
   The Azure context. If not provided, the function connects to the Azure account and gets the context.

.EXAMPLE
   Set-AdfToolsAuthToken -apiUrl "https://management.usgovcloudapi.net" 

   This command sets BaseApiUrl to "https://management.usgovcloudapi.net", which is the URL of the Azure Government cloud.

.INPUTS
   None. This function does not accept pipeline input.

.OUTPUTS
   None. This function does not return any output.

.NOTES

#>

function Set-AdfToolsAuthToken {
   param
   (
      [string]       $apiUrl
   )

   if ($apiUrl) {
      $script:BaseApiUrl = $apiUrl
      Write-Host "BaseApiUrl set to $apiUrl"
   }

}