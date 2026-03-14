# Getting Started with azure.datafactory.tools

**Related:** [Publishing](GUIDE/PUBLISHING.md) | [Main Documentation](../README.md)

## Installation

To install the module, open PowerShell command line window and run the following lines:

```powershell
Install-Module -Name azure.datafactory.tools -Scope CurrentUser
Import-Module -Name azure.datafactory.tools
```

### Upgrading from Previous Version

If you want to upgrade module from a previous version:

```powershell
Update-Module -Name azure.datafactory.tools
```

### Check Currently Available Version

```powershell
Get-Module -Name azure.datafactory.tools
```

**Source:** [PowerShell Gallery](https://www.powershellgallery.com/packages/azure.datafactory.tools)

## System Requirements

- **PowerShell:** Windows PowerShell 5.1, PowerShell Core 6.0 and above
- **Azure Module:** `Az.DataFactory` PowerShell module from Microsoft
- **Support:** Windows and Linux-based agents in Azure DevOps pipelines

## Module Overview

The **azure.datafactory.tools** module simplifies Azure Data Factory CI/CD processes by:

- Creating new ADF instances if they don't exist
- Deploying all types of ADF objects (Pipelines, DataSets, Linked Services, Data Flows, Triggers, etc.)
- Automatically determining the correct deployment order
- Replacing environment-specific values via configuration files
- Stopping/starting triggers intelligently
- Deleting objects not in source code
- Supporting incremental deployments for faster CI/CD

## Quick Start: Your First Deployment

### 1. Prepare Your Code Repository

Your ADF code should be organized in the following folder structure:

```
SQLPlayerDemo/
    dataflow/
    dataset/
    integrationRuntime/
    linkedService/
    pipeline/
    trigger/
```

> **Note:** Some folders may not exist if your ADF doesn't contain those object types.

**How to set up code repository?** Read: [Setting up Code Repository for Azure Data Factory v2](https://azureplayer.net/2018/10/setting-up-code-repository-for-azure-data-factory-v2/)

### 2. Basic Deployment

```powershell
$SubscriptionName = 'Your-Subscription-Name'
Set-AzContext -Subscription $SubscriptionName

$ResourceGroupName = 'rg-devops-factory'
$DataFactoryName = 'SQLPlayerDemo'
$Location = 'NorthEurope'
$RootFolder = 'c:\GitHub\AdfName\'

Publish-AdfV2FromJson `
    -RootFolder $RootFolder `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Location $Location
```

## Next Steps

- **Learn core concepts:** [Publishing Workflow](GUIDE/PUBLISHING.md)
- **Filter what to deploy:** [Publish Options](GUIDE/PUBLISH_OPTIONS.md)
- **Environment-specific values:** [Configuration & Stages](GUIDE/CONFIGURATION.md)
- **Fine-tune deployment:** [Selective Deployment](GUIDE/SELECTIVE_DEPLOYMENT.md)
- **All cmdlets:** [Cmdlet Reference](ADVANCED/CMDLET_REFERENCE.md)

---

[← Back to Main Documentation](../README.md)
