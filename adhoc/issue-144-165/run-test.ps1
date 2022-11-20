#Import-Module ".\azure.datafactory.tools.psd1" -Force
#Get-Module 
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'
$path = (.\adhoc\Get-RootPath.ps1)

. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session

# Prep
$params = @{
    DataFactoryName   = 'adf-simpledeployment-dev'
    ResourceGroupName = 'rg-blog-dev' 
    SubscriptionID    = (Get-AzContext).Subscription.Id
}

# Example 1
$DebugPreference = 'Continue'
$DebugPreference = 'SilentlyContinue'
$LinkedServiceName = 'LS_AzureKeyVault,LS_NotExist'
$LinkedServiceName = 'LS_NotExist'
$r = Test-AdfLinkedService @params -LinkedServiceName $LinkedServiceName
$r


# Example 2
$LinkedServiceNames = 'AzureSqlDatabase1,LS_ADLS'   # Comma-separated list   
Test-AdfLinkedService @params -LinkedServiceName $LinkedServiceNames


## Test connection with Service Principal
$params = @{
    DataFactoryName   = 'adf-simpledeployment-dev'
    ResourceGroupName = 'rg-blog-dev' 
    SubscriptionID    = (Get-AzContext).Subscription.Id
    TenantID          = "f331b859-caa3-4395-bc2d-546406838798"
    ClientID          = "e24c67cf-a065-491a-929e-86485e0f5d65"
    ClientSecret      = '***'
}
. .\adhoc\~~Load-all-cmdlets-locally.ps1   # Load to this session
$DebugPreference = 'Continue'
#$LinkedServiceName = 'LS_AzureKeyVault'
#$LinkedServiceName = 'LS_NotExist'
#$LinkedServiceName = 'LS_SQL_Stackoverflow'
$LinkedServiceName = 'LS_ADLS'
$LinkedServiceName = 'LS_SQL_GenericDb'
$LinkedServiceName = "$path\list2.json"
$r = Test-AdfLinkedService @params -LinkedServiceName $LinkedServiceName
$r | Format-Table
$r.Report
