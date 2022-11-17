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

#Run TestAdfCode function to validate JSON
Test-AdfCode -RootFolder "$RootFolder"

#Set deploy parameters
$opt = New-AdfPublishOption -FilterFilePath $IncludeExcludeFilePath
$opt.DeleteNotInSource = $DeleteNotInSource
$opt.StopStartTriggers = $true
$opt.DeployGlobalParams = $false
$opt.CreateNewInstance = $false

#Deploy to Data Factory
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Stage $Stage -Option $opt

