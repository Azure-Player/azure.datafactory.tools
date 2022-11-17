param
(
    [parameter(Mandatory = $true)] [String] $SubscriptionName,
    [parameter(Mandatory = $true)] [String] $ResourceGroupName,
    [parameter(Mandatory = $true)] [String] $DataFactoryName,
    [parameter(Mandatory = $true)] [String] $Location,
    [parameter(Mandatory = $true)] [String] $RootFolder,
    [switch] $DeleteNotInSource = $false,
    [String] $Stage = "dev",
    [parameter(Mandatory = $true)] [String] $IncludeExcludeFilePath
)

#Install-Module -Name Az.DataFactory -Scope CurrentUser -Force # required by azure.datafactory.tools
Install-Module -Name azure.datafactory.tools -Scope CurrentUser -Force
Import-Module -Name azure.datafactory.tools

# Run TestAdfCode function to validate JSON
$RootFolder = (.\adhoc\Get-RootPath.ps1)
Test-AdfCode -RootFolder "$RootFolder\adf1"


# Set deploy parameters
$IncludeExcludeFilePath = "$RootFolder\adf1\publish-includeexclude-objects.txt"
$opt = New-AdfPublishOption -FilterFilePath $IncludeExcludeFilePath
$opt.DeleteNotInSource = $true
$opt.StopStartTriggers = $true
$opt.DeployGlobalParams = $false
$opt.CreateNewInstance = $true

# init vars
$SubscriptionName = "MVP"
$ResourceGroupName = 'rg-devops-factory'
$DataFactoryName = 'adf-kn-issue-223'
$Location = 'northeurope'

# Deploy to Data Factory - leg 1
Publish-AdfV2FromJson -RootFolder "$RootFolder\adf1" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Stage $Stage -Option $opt

# Deploy to Data Factory - leg 2
# Set deploy parameters
$IncludeExcludeFilePath = "$RootFolder\adf2\publish-includeexclude-objects.txt"
$opt = New-AdfPublishOption -FilterFilePath $IncludeExcludeFilePath
$opt.DeleteNotInSource = $true
$opt.StopStartTriggers = $true
$opt.DeployGlobalParams = $false
$opt.CreateNewInstance = $true

## THIS!!! By default is True
$opt.DoNotDeleteExcludedObjects = $false

Publish-AdfV2FromJson -RootFolder "$RootFolder\adf2" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Stage $Stage -Option $opt

$VerbosePreference = 'Continue'


