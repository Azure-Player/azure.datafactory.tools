[![Build status](https://dev.azure.com/sqlplayer/azure.datafactory.tools/_apis/build/status/azure.datafactory.tools-CI)](https://dev.azure.com/sqlplayer/azure.datafactory.tools/_build/latest?definitionId=26)
![PSGalleryStatus](https://vsrm.dev.azure.com/sqlplayer/_apis/public/Release/badge/ee3bd4b9-1ccf-4a86-89a0-a9d5dcd1918a/1/1)
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/azure.datafactory.tools?label=PowerShell%20Gallery)](https://www.powershellgallery.com/packages/azure.datafactory.tools)

# azure.datafactory.tools

PowerShell module to help simplify Azure Data Factory CI/CD processes. This module was created to meet the demand for a quick and trouble-free deployment of an Azure Data Factory instance to another environment.  
The main advantage of the module is the ability to publish all the Azure Data Factory service code from JSON files by calling one method. The method supports now:  
* Creation of Azure Data Factory, if not exist
* Deployment of all type of objects: pipelines, datasets, linked services, data flows, triggers, integration runtimes
* Finding the **right order** for deploying objects (no more worrying about object names)
* Build-in mechanism to replace the properties with the indicated values (CSV file)
* Stop/start triggers
* Dropping objects when not exist in the source (code)
* Filtering (include or exclude) objects to be deployed by name and/or type
* Publish options allow you to control:
  * Whether stop and restarting triggers
  * Whether delete or not objects not in the source
  * Whether create or not a new instance of ADF if it not exist

The following features coming soon:
* Build function to support validation of files, dependencies and config
* Unit Tests of selected Pipelines and Linked Services

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

# Examples

Publish (entire) ADF code into ADF service in Azure:

```powershell
Publish-AdfV2FromJson 
   -RootFolder            <String>
   -ResourceGroupName     <String>
   -DataFactoryName       <String>
   -Location              <String>
   [-Stage]               <String>
   [-Option]              <AdfPublishOption>
   [-Method]              <String>
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

## Other environments (stage)

Use optional ```[-Stage]``` parameter to prepare json files of ADF with appropriate values for properties and deploy to another environment correctly. See section: **How it works / Step: Replacing all properties environment-related** for more details.  


> Detailed *Wiki* documentation - coming soon.

## Publish Options

The options allows you control which objects should be deployed by including or excluding them from the list. First of all you need to create the object:

```powershell
# Example 0: Creating Publish Option object
$opt = New-AdfPublishOption
```
`AdfPublishOption` contains the following options:  
* [HashTable] **Includes** - defines a list of objects to be published (default: *empty*)  
* [HashTable] **Excludes** - defines a list of objects to be NOT published (default: *empty*)  
* [Boolean] **DeleteNotInSource** - indicates whether the objects not in the source should be deleted or not (default: *false*)  
* [Boolean] **StopStartTriggers** - indicates whether the triggers would be stopped and restarted during the deployment (default: *true*)
* [Boolean] **CreateNewInstance** - specifies whether the target ADF should be created when it does not exist. When target ADF doesn't exist and this option is set to *false* then `Publish-AdfV2FromJson` function fails.  (default: *true*)

Subsequently, you can define the needed options:

```powershell
# Example 1: Including objects by type and name pattern
$opt = New-AdfPublishOption
$opt.Includes.Add("pipeline.Copy*", "")
$opt.DeleteNotInSource = $false

# Example 2: Excluding objects by type
$opt = New-AdfPublishOption
$opt.Excludes.Add("linkedService.*", "")
$opt.Excludes.Add("integrationruntime.*", "")
$opt.Excludes.Add("trigger.*", "")
$opt = New-AdfPublishOption

# Example 3: Excluding all objects from deployment
$opt = New-AdfPublishOption
$opt.Excludes.Add("*", "")
$opt.StopStartTriggers = $false

# Example 4: Including only one object to deployment
$opt = New-AdfPublishOption
$opt.Includes.Add("pipeline.Wait1", "")
$opt.StopStartTriggers = $false
```

> Bear in mind that *Includes* and *Excludes* lists are **rules out each other**.  
Objects would be excluded from deployment only if *Includes* list remains empty.  
When both lists are empty - all objects going to be published.

Once you define all necessary options, just add the parameter to **Publish** function:  
```powershell
Publish-AdfV2FromJson -RootFolder "$RootFolder" `
   -ResourceGroupName "$ResourceGroupName" `
   -DataFactoryName "$DataFactoryName" `
   -Location "$Location" `
   -Option $opt
```

### Pattern (WildCard)
As you probably noticed, you can use some patterns when defining name or type for objects to be included of excluded to/from deployment. 
To determine whether an object matches to the pattern (wildcard) - module uses `-like` operator known in PowerShell.
Therefore you can use the following combinations:  
```
trigger.*
dataset.DS_*
*.PL_*
linkedService.???KeyVault*
pipeline.ScdType[123]
```
Full name of objects supported by the module is built of: `{Type}.{Name}`  
All potential combinations can be found in code repository of ADF:  
*Type* - name of folder  
*Name* - name of file (without JSON extension)

> More info about wildcard: [About Wildcard](https://docs.microsoft.com/en-gb/powershell/module/microsoft.powershell.core/about/about_wildcards?view=powershell-5.1)

## Publising objects from selected ADF's folder only
Although providing pattern of selected object names to be published gives great flexibility in terms of part-deployment, it might not cover other scenario. When your ADF has objects organised in folders, you may want to publish objects only within that folder, no matter what will change in the future.  
Let's take the following ADF as an example:  

![Azure Data Factory Resources](./media/adf-folders.png)  
If you want to publish only objects from "Copy" folder(s), you must perform three steps before publish:
1) Load all ADF objects from your code (local folder)
2) Execute function which returns list of objects located in selected folder in ADF
3) Add returned list (of objects) to **Includes** in **Publish Option**
> Sounds complicated? You have tools to do all those things!
```PowerShell
# Step 1
$adf = Import-AdfFromFolder -RootFolder "$RootFolder" -FactoryName $DataFactoryName

# Step 2
$list1 = $adf.GetObjectsByFolderName('Copy')

# Step 3
$opt = New-AdfPublishOption
$opt.Includes += $list1

# Finally: Run Publish as usual
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Option $opt
```

Naturally, you can add more objects from different folder. Just repeat steps 2-3:
```PowerShell
$list2 = $adf.GetObjectsByFolderName('JSON')
$opt.Includes += $list2
```

> **Remember:** Current version will not publish related objects when list of objects would be provided in *Includes* publish options. You must ensure that all dependent objects are already exist on target ADF service.

## Publishing Method

Parameter: ```Method``` (optional)  
Currently ```Publish-AdfV2FromJson``` cmdlet contains two methods of publishing: 
* AzDataFactory, 
* AzResource *(default)*.  

**AzResource** method has been introduced in version 0.9.0 due to bugs in **Az.DataFactory** PowerShell module and uses **Az.Resources** module to deploy Data Factory resources. However, if you still want to use Az.DataFactory module for deployments for any reasons - just use this parameter and specify the first method.


# How it works

This section describes what the function ```Publish-AdfV2FromJson``` does step by step.

## Step: Create ADF (if not exist)

You must have appropriate permission to create new instance.  
*Location* parameter is required for this action.

## Step: Replacing all properties environment-related

This step will be executed only when `[Stage]` parameter has been provided.  
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
pipeline,PL_CopyMovies,activities[0].outputs[0].parameters.BlobContainer,UAT
pipeline,PL_CopyMovies_with_param,parameters.DstBlobContainer.defaultValue,UAT
pipeline,PL_Wait_Dynamic,parameters.WaitInSec,"{'type': 'int32','defaultValue': 22}"
# This is comment - the line will be omitted
```
> You can replace any property with that method.

There are 4 columns in CSV file:
- type - Type of object. It's the same as folder where the object's file located
- name - Name of objects. It's the same as json file in the folder
- path - Path of the property's value to be replaced within specific json file
- value - Value to be set

Column `type` accepts one of the following values only:
- integrationRuntime
- pipeline
- dataset
- dataflow
- linkedService
- trigger

You can define 3 types of values in column `value`: number, string, (nested) JSON object.  
If you need to use comma (,) in `value` column - remember to enclose entire value within double-quotes ("), like in this example below:
```
pipeline,PL_Wait_Dynamic,parameters.WaitInSec,"{'type': 'int32','defaultValue': 22}"
```


Optional parameter. When defined, process will replace all properties defined in (csv) configuration file.
The parameter can be either full path to csv file (must ends with .csv) or just stage name.
When you provide parameter value 'UAT' the process will try open config file located .\deployment\config-UAT.csv

> Use optional [-Stage] parameter when executing ```Publish-AdfV2FromJson``` module to replace values for/with properties specified in config file(s).

There are 2 ways to provide value for `Stage` parameter:  
### Stage value as environment code/name

You can provide short environment code, e.g. UAT, PROD for `Stage` parameter.  
In that case, planning deployment into UAT and PROD environments you need to create these files (subfolder `deployment` in relation to main ADF location):
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
> File name must follow the pattern: **config-{stage}.csv** and be located in folder named: **deployment**.


### Stage value as full path to CSV config file
The second way is to provide full path to configuration file.  
For example, if you provide `c:\MyCode\adf\uat-parameters.csv`, an exact file will be use to read configuration as the value ends with ".csv". Although, in that case, the file may be located anywhere, it's recommended to keep them along with other ADF files. 


## Step: Stoping triggers
This block stops all triggers which must be stopped due to deployment.
> Operation might be skip when `StopStartTriggers = false` in *Publish Options*

## Step: Deployment of ADF objects
This step is actually responsible to do all the stuff.
The mechanism is smart enough to publish all objects in the right order, thence a developer doesn't need to care of object names due to deployment failure any longer.
> Find out *Publish Option* capabilities in terms of filtering objects intended to be deployed.

## Step: Deleting objects not in source
This process removes all objects from ADF service whom couldn't be found in the source (ADF code).  
The mechanism is smart enough to dropping the objects in right order.

> Operation might be skip when `DeleteNotInSource = false` in *Publish Options*

## Step: Restarting all triggers
Restarting all triggers that should be enabled.
> Operation might be skip when `StopStartTriggers = false` in *Publish Options*

# Publish from Azure DevOps

There are two ways you can deploy Azure Data Factory with this approach (directly from code) within Azure DevOps Pipeline using:  
* Publish Azure Data factory task (recommended)
* Azure PowerShell task

## Using Publish Azure Data factory (task)

Custom Build/Release Task for Azure DevOps has been prepared as a very convenient way of configuring deployment task in Release Pipeline (Azure DevOps). Although it's only UI put on top of azure.datafactory.tools PS module, it gives users great experience if they don't have PowerShell skills or perhaps prefer using clear and simple fields configuration approach.  
The "Publish Azure Data factory" task is available for free and open-source. 
You can install it from Microsoft MarketPlace onto your organisation.  
More information: [Marketplace](https://marketplace.visualstudio.com/items?itemName=SQLPlayer.DataFactoryTools)
| [Source code and documentation](https://github.com/SQLPlayer/azure.datafactory.devops)

## Using Azure PowerShell (task)

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
