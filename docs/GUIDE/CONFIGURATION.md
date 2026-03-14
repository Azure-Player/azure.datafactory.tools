# Configuration & Environment Replacement

**Related:** [Publishing](PUBLISHING.md) | [Publish Options](PUBLISH_OPTIONS.md) | [Main Documentation](../../README.md)

## Overview

The `-Stage` parameter enables environment-specific value replacement. Before deployment, the module reads a configuration file and replaces selected properties with environment-specific values.

## Why Configuration Files?

ADF JSON files contain hardcoded values that differ between environments:
- Data Factory name
- Key Vault URLs
- Linked Service connection strings
- Dataset properties
- Pipeline parameters

Configuration files allow you to:
- Keep one set of source files
- Deploy to different environments with different values
- Replace values during CI/CD without manual editing

## Using the Stage Parameter

The `-Stage` parameter enables configuration. It can be:
1. **Short name** (UAT, PROD) → loads `deployment/config-{stage}.csv`
2. **Full file path** → loads exact file (must end with .csv or .json)

### Example: Deploy to UAT

```powershell
Publish-AdfV2FromJson `
    -RootFolder $RootFolder `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Location $Location `
    -Stage 'UAT'
```

This automatically loads `deployment/config-uat.csv` from your ADF code folder.

## Folder Structure

```
SQLPlayerDemo/
    dataflow/
    dataset/
    deployment/               ← Add this folder
        config-dev.csv
        config-uat.csv
        config-prod.csv
    factory/
    integrationRuntime/
    linkedService/
    pipeline/
    trigger/
```

## CSV Configuration Format

### Structure

```
type,name,path,value
linkedService,LS_AzureKeyVault,typeProperties.baseUrl,"https://kv-blog-uat.vault.azure.net/"
linkedService,LS_BlobSqlPlayer,typeProperties.connectionString,"DefaultEndpointsProtocol=https;AccountName=blobstorageuat;"
pipeline,PL_CopyMovies,activities[0].outputs[0].parameters.BlobContainer,UAT
# This is a comment - line is ignored
```

### Column Definitions

#### Column: type
Object type (folder name). One of:
- `integrationRuntime`
- `pipeline`
- `dataset`
- `dataflow`
- `linkedService`
- `trigger`
- `managedVirtualNetwork`
- `managedPrivateEndpoint`
- `factory` (for Global Parameters)
- `credential`

#### Column: name
Object name (JSON file name without extension). **Supports wildcards** since v0.19:

```
dataset,DS_*,properties.xyz,ABC      # Applies to DS_Sales, DS_Customer, etc.
linkedService,LS_*,typeProperties.connectionString,"..."
```

#### Column: path
Location of property within JSON object. Several formats supported:

**Update existing property (default):**
```
linkedService,LS_AzureKeyVault,typeProperties.baseUrl,"https://..."
```

**Remove property (prefix with `-`):**
```
linkedService,LS_AzureKeyVault,-typeProperties.encryptedCredential,
```

**Add new property (prefix with `+`):**
```
linkedService,LS_AzureKeyVault,+typeProperties.accountKey,"$($Env:KEY)"
```

**Using array indices:**
```
pipeline,PL_Demo,activities[0].name,MyActivity               # Integer index
pipeline,PL_Demo,activities["Copy Data"].waitTime,30         # Name-based key
```

**Using root path (with `$`):**
```
factory,ADFName,"$.properties.globalParameters.envName.value",PROD
```

> If path doesn't start with `$`, it applies relative to `properties` node.
> These are equivalent:
> ```
> linkedService,LS_AzureKeyVault,typeProperties.baseUrl,"https://..."
> linkedService,LS_AzureKeyVault,$.properties.typeProperties.baseUrl,"https://..."
> ```

#### Column: value
The replacement value. Three types supported:

**String:**
```
linkedService,LS_BlobSqlPlayer,typeProperties.connectionString,"Default..."
```

**Number:**
```
pipeline,PL_Demo,activities[0].timeout,30
```

**JSON Object:**
```
pipeline,PL_Dynamic,parameters.WaitInSec,"{'type': 'int32','defaultValue': 22}"
```

> Use double-quotes around values containing commas.

## Dynamic Values with Tokens

Use PowerShell environment variable tokens for dynamic replacement:

```
linkedService,AKV,typeProperties.baseUrl,"https://$($Env:KEYVAULT_NAME).vault.azure.net/"
factory,ADF,$.properties.description,"Deployed to $($Env:ENVIRONMENT) on $(Get-Date)"
```

Azure DevOps pipeline variables automatically become environment variables, so you can:
```powershell
# In Azure DevOps task:
# - Set variable: KEYVAULT_NAME = kv-prod
# - Set variable: ENVIRONMENT = PROD
```

Then use in config:
```
linkedService,AKV,typeProperties.baseUrl,"https://$($Env:KEYVAULT_NAME).vault.azure.net/"
```

## CSV Examples

### Complete Configuration File

```
type,name,path,value
# Key Vault
linkedService,LS_AzureKeyVault,typeProperties.baseUrl,"https://kv-blog-uat.vault.azure.net/"

# Blob Storage
linkedService,LS_BlobSqlPlayer,typeProperties.connectionString,"DefaultEndpointsProtocol=https;AccountName=blobstorageuat;EndpointSuffix=core.windows.net;"

# SQL Database
linkedService,LS_SqlServer,typeProperties.server,"sqlserver-uat.database.windows.net"
linkedService,LS_SqlServer,typeProperties.database,"dbname_uat"

# Pipeline Parameters
pipeline,PL_CopyMovies,activities[0].outputs[0].parameters.BlobContainer,UAT
pipeline,PL_CopyMovies_with_param,parameters.DstBlobContainer.defaultValue,UAT

# Remove Dev Credentials
linkedService,LS_DatabaseDev,-typeProperties.encryptedCredential,

# Add Environment Variables
factory,MyADF,"+$.properties.globalParameters.Environment.value",uat
factory,MyADF,"+$.properties.globalParameters.DeployDate.value","$(Get-Date)"

# Wildcard Pattern
dataset,DS_*,properties.location.path,/data/uat/

# Multiple objects
linkedService,LS_*,typeProperties.tenant,"$($Env:TENANT_ID)"
```

## JSON Configuration Format

Alternative to CSV: JSON configuration files (v1.5+). Use `-Stage` with full file path:

```powershell
Publish-AdfV2FromJson -Stage 'c:\config\uat-parameters.json' ...
```

### JSON Structure

```json
{
  "LS_AzureDatabricks": [
    {
      "name": "$.properties.typeProperties.existingClusterId",
      "value": "$($Env:DatabricksClusterId)",
      "action": "add"
    },
    {
      "name": "$.properties.typeProperties.encryptedCredential",
      "value": "",
      "action": "remove"
    }
  ],
  "LS_AzureKeyVault": [
    {
      "name": "$.properties.typeProperties.baseUrl",
      "value": "https://kv-$($Env:Environment).vault.azure.net/",
      "action": "update"
    }
  ],
  "PL_Demo": [
    {
      "name": "$.activities[1].typeProperties.waitTimeInSeconds",
      "value": "30",
      "action": "update"
    },
    {
      "name": "$.activities['Copy Data'].typeProperties.waitTimeInSeconds",
      "value": "30",
      "action": "update"
    }
  ]
}
```

**Actions:**
- `update`: Replace existing value (default)
- `add`: Add new property
- `remove`: Delete property

## Deployment with Configuration

```powershell
# Load and apply config-uat.csv
Publish-AdfV2FromJson `
    -RootFolder $RootFolder `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Location $Location `
    -Stage 'UAT'

# Or with full path to config
Publish-AdfV2FromJson `
    -RootFolder $RootFolder `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Location $Location `
    -Stage 'c:\configs\custom-config.csv'
```

## Common Patterns

### Multi-Environment Setup

```
deployment/
    config-dev.csv
    config-test.csv
    config-uat.csv
    config-prod.csv
    azure-keyvault.csv    # Stored in KeyVault instead
```

### Unified Storage Accounts by Environment

```
linkedService,LS_Blob,typeProperties.connectionString,"DefaultEndpointsProtocol=https;AccountName=storage$($Env:ENVIRONMENT);EndpointSuffix=core.windows.net;"
dataset,DS_*,properties.location.fileName,data/$($Env:ENVIRONMENT)/$(Get-Date -Format 'yyyy-MM-dd')
```

### Conditional Global Parameters

```
factory,MyADF,"+$.properties.globalParameters.IsProd.value",$($Env:ENVIRONMENT -eq 'PROD')
factory,MyADF,"+$.properties.globalParameters.Environment.value",$($Env:ENVIRONMENT)
```

## Error Handling

### Missing Configuration Item

If a config file references an object or property that doesn't exist:
- **FailsWhenConfigItemNotFound = true** (default): Deployment fails
- **FailsWhenConfigItemNotFound = false**: Warning is printed, deployment continues

```powershell
$opt = New-AdfPublishOption
$opt.FailsWhenConfigItemNotFound = $false
```

### Missing Path

If a property path doesn't exist in the JSON:
- **FailsWhenPathNotFound = true** (default): Deployment fails
- **FailsWhenPathNotFound = false**: Warning is printed, deployment continues

## See Also

- [Publishing Workflow](PUBLISHING.md)
- [Publish Options - Filtering](PUBLISH_OPTIONS.md)
- [Selective Deployment](SELECTIVE_DEPLOYMENT.md)

---

[← Back to Main Documentation](../../README.md)
