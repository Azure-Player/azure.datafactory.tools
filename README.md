[![Build status](https://dev.azure.com/sqlplayer/azure.datafactory.tools/_apis/build/status/azure.datafactory.tools-CI)](https://dev.azure.com/sqlplayer/azure.datafactory.tools/_build/latest?definitionId=26)
![PSGalleryStatus](https://vsrm.dev.azure.com/sqlplayer/_apis/public/Release/badge/ee3bd4b9-1ccf-4a86-89a0-a9d5dcd1918a/1/1)

# azure.datafactory.tools

PowerShell module to help simplify Azure Data Factory CI/CD processes. This module was created to meet the demand for a quick and trouble-free deployment of an Azure Data Factory instance to another environment.  
The main advantage of the module is the ability to publish all the Azure Data Factory service code from JSON files by calling one method. The method supports now:  
* Creation of Azure Data Factory, if not exist
* Deployment of all type of objects: pipelines, datasets, linked services, data flows, triggers
* Finding the **right order** for deploying objects (no more worrying about object names)
* Build-in mechanism to replace the properties with the indicated values (CSV file)
* Stop/start triggers

The following features coming soon:
* Dropping objects when not exist in the source (code)
* Filtering objects to be deployed by name and type
* Build function to support validation of files, dependencies and config

> The module publish code which is created and maintanance by ADF in code repository, when configured.

# Overview

This module works for Azure Data Factory **V2 only** and uses ```Az.DataFactory``` PowerShell module from Microsoft for management of objects in ADF service.  
Supports Windows PowerShell 5.1 only. In the nearest future the module will be compatible with PowerShell Core as well.

# How to start

## Install-Module

To install the module, open PowerShell command line window and run the following lines:

```powershell
Install-Module -Name azure.datafactory.tools -Scope CurrentUser
Import-Module -Name azure.datafactory.tools
```

If you want to upgrade module from a previous version:

```powershell
Update-Module -Name azure.datafactory.tools
```

Check your currently available version of module:
```powershell
Get-Module -Name azure.datafactory.tools
```

Source: https://www.powershellgallery.com/packages/azure.datafactory.tools


## Publish Azure Data Factory 

This module publishes all objects from JSON files stored by ADF in code repository (collaboration branch). Bear in mind we are talking about *master* branch, NOT *adf_publish* branch.  
If you want to deploy from *adf_publish* branch - read this article: [Deployment of Azure Data Factory with Azure DevOps](https://sqlplayer.net/2019/06/deployment-of-azure-data-factory-with-azure-devops/).

## Where is my code?
If you never seen code of your Azure Data Factory instance - you need to configure code repository for you ADF. This article helps you to do that: [Setting up Code Repository for Azure Data Factory v2](https://sqlplayer.net/2018/10/setting-up-code-repository-for-azure-data-factory-v2/).  
Once you set up code repository, clone the repo and pull (download) onto local machine. The folder structure should looks like this:  
```
SQLPlayerDemo  
    dataflow  
    dataset  
    integrationRuntime  
    linkedService  
    pipeline  
    trigger  
```

Some of these folders might not exist when ADF has none of that kind of objects.

## Examples

Publish ADF code into ADF service in Azure:

```powershell
Publish-AdfV2FromJson 
   -RootFolder            <String>
   -ResourceGroupName     <String>
   -DataFactoryName       <String>
   -Location              <String>
[-Stage]                <String>
```

Assuming your ADF names ```SQLPlayerDemo``` and code located in ```c:\GitHub\AdfName\```, replace the values for *SubscriptionName*, *ResourceGroupName*, *DataFactoryName* and run the following command using PowerShell CLI:

```powershell
$SubscriptionName = 'Subscription'
Set-AzContext -Subscription $SubscriptionName
$ResourceGroupName = 'rg-devops-factory'
$DataFactoryName = "SQLPlayerDemo"
$Location = "NorthEurope"
$RootFolder = "c:\GitHub\AdfName\"
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location"
```

### Other environments (stage)

Use optional ```[-Stage]``` parameter to prepare json files of ADF with appropriate values for properties and deploy to another environment correctly. See section: **How it works / Step 2** for more details.


> Detailed *Wiki* documentation - coming soon.

# How it works

This section describes what the function ```Publish-AdfV2FromJson``` does step by step.

## Step 1: Create ADF (if not exist)

You must have appropriate permission to create new instance.  
*Location* parameter is required for this action.

## Step 2: Replacing all properties environment-related

The whole concept of CI & CD (Continuous Integration and Continuous Delivery) process is to deploy automatically and riskless onto target infrastructure, supporting multi-environments. Each environment (or stage) to be exact the same code except selected properties. Very often these properties are:  
- Data Factory name
- Azure Key Vault URL (endpoint)
- Selected properties of Linked Services 
- Some variables
- etc.

All these values are hold among JSON files in code repository and due to their specifics - they are not parametrised as it happens in ARM template.
That is the reason of the need of replacing selected object's parameters into one specified for particular environment. The changes must be done just before deployment.

In order to address that needs, the process are able to read flat **configuration file** with all required values **per environment**. Below is the example of such config file:
```
type,name,path,value
linkedService,LS_AzureKeyVault,typeProperties.baseUrl,"https://kv-blog-uat.vault.azure.net/"
linkedService,LS_BlobSqlPlayer,typeProperties.connectionString,"DefaultEndpointsProtocol=https;AccountName=blobstorageuat;EndpointSuffix=core.windows.net;"
```
There are 4 columns in CSV file:
- type - Type of object. It's the same as folder where the object's file located
- name - Name of objects. It's the same as json file in the folder
- path - Path of the property's value to be replaced within specific json file
- value - Value to be set

> File name must follow the pattern: **config-{stage}.csv** and be located in folder named: **deployment**.

For example, planning deployment into UAT and PROD environments you need to create these files:
```
SQLPlayerDemo  
    dataflow  
    dataset
    deployment               (new folder)  
        config-uat.csv       (file for UAT environment)
        config-prod.csv      (file for PROD environment)
    integrationRuntime  
    linkedService  
    pipeline  
    trigger  
```
> Use optional [-Stage] parameter when executing ```Publish-AdfV2FromJson``` module to replace values for/with properties specified in config file(s).

## Step 3: Deployment of all ADF objects
This step is actually responsible to do all the stuff.
More details soon.


# Publish from Azure DevOps

> Custom Build/Release Task for Azure DevOps will be prepared and shared in Marketplace for free soon. Until then leverage PowerShell Task to execute the function from this module.

Having PowerShell module it is very ease to configure Release Pipeline in Azure DevOps to publish ADF code as if from local machine. All steps you must create are:  
- Download & install ```Az.DataFactory``` and ```azure.datafactory.tools``` PowerShell modules
- Execute ```Publish-AdfV2FromJson``` method with parameters

Both steps you can find here:  
```powershell
# Step 1
Install-Module Az.DataFactory -MinimumVersion "1.7.0" -Force
Install-Module -Name "azure.datafactory.tools" -Force
Import-Module -Name "azure.datafactory.tools" -Force

# Step 2
Publish-AdfV2FromJson -RootFolder "$(System.DefaultWorkingDirectory)/_ArtifactName/" -ResourceGroupName "$(ResourceGroupName)" -DataFactoryName "$(DataFactoryName)" -Location "$(Location)" -Stage "$(Release.EnvironmentName)"
```

YAML:
```yaml
variables:
  ResourceGroupName: 'rg-devops-factory'
  DataFactoryName: 'SQLPlayerDemo'
steps:
- powershell: |
   Install-Module Az.DataFactory -MinimumVersion "1.7.0" -Force
   Install-Module -Name "azure.datafactory.tools" -Force
   Import-Module -Name "azure.datafactory.tools" -Force
  displayName: 'PowerShell Script'
steps:
- task: AzurePowerShell@4
  displayName: 'Azure PowerShell script: InlineScript'
  inputs:
    azureSubscription: 'Subscription'
    ScriptType: InlineScript
    Inline: |
     Publish-AdfV2FromJson -RootFolder "$(System.DefaultWorkingDirectory)/_ArtifactName_/" -ResourceGroupName "$(ResourceGroupName)" -DataFactoryName "$(DataFactoryName)" -Location "$(Location)" -Stage "$(Release.EnvironmentName)"
     
    FailOnStandardError: true
    azurePowerShellVersion: LatestVersion```
```

# Release Notes

New features, bug fixes and changes [can be found here](https://github.com/SQLPlayer/azure.datafactory.tools/blob/master/changelog.md).

# Misc

## New feature requests
Tell me your thoughts or describe your specific case or problem.  
For any requests on new features please raise a new issue here: [New issue](https://github.com/SQLPlayer/azure.datafactory.tools/issues)  

More articles and useful links on [SQLPlayer blog - ADF page](https://sqlplayer.net/adf/).
