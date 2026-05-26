# Publish Options - Filtering & Controls

**Related:** [Publishing](PUBLISHING.md) | [Configuration](CONFIGURATION.md) | [Selective Deployment](SELECTIVE_DEPLOYMENT.md) | [Main Documentation](../../README.md)

## Overview

`AdfPublishOption` objects control which objects get deployed and how the deployment behaves.

## Creating Publish Options

```powershell
$opt = New-AdfPublishOption
```

## Available Options

### Filtering Options

#### Includes
- **Type:** HashTable
- **Default:** Empty
- **Purpose:** List of objects TO deploy (whitelist)
- **Pattern:** `{Type}.{Name}@{Folder}` with wildcards supported

#### Excludes
- **Type:** HashTable
- **Default:** Empty
- **Purpose:** List of objects to NOT deploy (blacklist)
- **Pattern:** `{Type}.{Name}@{Folder}` with wildcards supported

**Important:** Includes and Excludes are mutually exclusive:
- If **Includes** is not empty: ONLY objects in Includes will deploy
- If **Includes** is empty: ALL objects except those in Excludes will deploy
- If both are empty: ALL objects will deploy

### Deployment Options

#### DeleteNotInSource
- **Type:** Boolean
- **Default:** false
- **Purpose:** Delete ADF objects that don't exist in source code

#### StopStartTriggers
- **Type:** Boolean
- **Default:** true
- **Purpose:** Stop triggers before deployment, restart after

#### CreateNewInstance
- **Type:** Boolean
- **Default:** true
- **Purpose:** Create target ADF if it doesn't exist (fails if false and ADF missing)

#### DeployGlobalParams
- **Type:** Boolean
- **Default:** true
- **Purpose:** Deploy Global Parameters (does nothing if not defined)

### Error Handling Options

#### FailsWhenConfigItemNotFound
- **Type:** Boolean
- **Default:** true
- **Purpose:** Fail deployment if config item references missing object (vs. warning only)

#### FailsWhenPathNotFound
- **Type:** Boolean
- **Default:** true
- **Purpose:** Fail deployment if config path doesn't exist (vs. warning only)

### Trigger Control Options

#### StopStartTriggers (see also: TriggerStopMethod, TriggerStartMethod)
- **Type:** Boolean
- **Default:** true

#### DoNotStopStartExcludedTriggers
- **Type:** Boolean
- **Default:** false
- **Purpose:** Don't stop excluded triggers (only meaningful with StopStartTriggers=true)

#### DoNotDeleteExcludedObjects
- **Type:** Boolean
- **Default:** true
- **Purpose:** Protect excluded objects from deletion (only meaningful with DeleteNotInSource=true)

#### TriggerStopMethod
- **Type:** Enum
- **Default:** AllEnabled
- **Values:**
  - `AllEnabled`: Stop all active triggers
  - `DeployableOnly`: Stop only triggers being deployed
- **Use Case:** Selective/incremental deployment where you don't want to stop unrelated triggers

#### TriggerStartMethod
- **Type:** Enum
- **Default:** BasedOnSourceCode
- **Values:**
  - `BasedOnSourceCode`: Use source files/config to determine trigger status
  - `KeepPreviousState`: Restore states from before deployment (new triggers: disabled)
- **Use Case:** Avoid changing trigger status when deploying unrelated objects

### Incremental Deployment Options

#### IncrementalDeployment
- **Type:** Boolean
- **Default:** false
- **Purpose:** Deploy only changed objects

#### IncrementalDeploymentStorageUri
- **Type:** String
- **Default:** (none)
- **Purpose:** Azure Storage location for deployment state file
- **Example:** `https://sqlplayer2020.file.core.windows.net/adftools`

## Usage Examples

### Example 1: Include Pipelines Beginning with "Copy"

```powershell
$opt = New-AdfPublishOption
$opt.Includes.Add('pipeline.Copy*', '')
$opt.DeleteNotInSource = $false
```

### Example 2: Exclude Infrastructure Objects

```powershell
$opt = New-AdfPublishOption
$opt.Excludes.Add('linkedService.*', '')
$opt.Excludes.Add('integrationruntime.*', '')
$opt.Excludes.Add('trigger.*', '')
```

### Example 3: Exclude Everything (Dry Run / Validation)

```powershell
$opt = New-AdfPublishOption
$opt.Excludes.Add('*', '')
$opt.StopStartTriggers = $false
```

### Example 4: Deploy Single Object

```powershell
$opt = New-AdfPublishOption
$opt.Includes.Add('pipeline.Wait1', '')
$opt.StopStartTriggers = $false
```

### Example 5: Ignore Missing Config Items

```powershell
$opt = New-AdfPublishOption
$opt.FailsWhenConfigItemNotFound = $false
# Warnings will be printed instead of failing
```

### Example 6: Incremental Deployment

```powershell
$opt = New-AdfPublishOption
$opt.IncrementalDeployment = $true
$opt.IncrementalDeploymentStorageUri = 'https://storageaccount.file.core.windows.net/adftools'
```

### Example 7: Selective Deployment with Smart Triggers

```powershell
$opt = New-AdfPublishOption
$opt.Includes.Add('pipeline.ImportData', '')
$opt.Includes.Add('pipeline.TransformData', '')
$opt.TriggerStopMethod = 'DeployableOnly'    # Don't stop unrelated triggers
$opt.TriggerStartMethod = 'KeepPreviousState' # Keep previous trigger states
```

## Pattern Matching (Wildcards)

The module uses PowerShell's `-like` operator for pattern matching. Supported wildcards:

```
*              Matches zero or more characters
?              Matches exactly one character
[abc]          Matches 'a', 'b', or 'c'
[!abc]         Matches anything except 'a', 'b', or 'c'
```

### Pattern Examples

```
trigger.*                          # All triggers
dataset.DS_*                       # Datasets starting with DS_
*.PL_*@test*                       # Objects with PL_ in name, in folder containing "test"
linkedService.???KeyVault*         # Any length, then "KeyVault"
pipeline.ScdType[123]              # ScdType1, ScdType2, or ScdType3
managedVirtualNetwork*.*           # All managedVirtualNetwork objects
*managedPrivateEndpoint.*          # All managedPrivateEndpoint objects
factory.*                          # Factory-level objects
```

### Full Object Name Format

Objects are referenced as: `{Type}.{Name}@{Folder}`

- **Type:** Folder name (pipeline, dataset, linkedService, trigger, etc.)
- **Name:** JSON file name (without .json extension)
- **Folder:** ADF folder path (optional, for organizational purposes)

Example: `pipeline.CopyData@ETL` or `linkedService.SqlServer`

## Loading Rules from File

Instead of hardcoding includes/excludes, load them from a file:

```powershell
$opt = New-AdfPublishOption -FilterFilePath '.\deployment\rules.txt'
```

### Filter File Format

Prefix each line with `+` (include) or `-` (exclude):

```
+pipeline.*           # Include all pipelines
trigger.*             # Include all triggers (+ is default)
-*.SharedIR*          # Exclude objects with SharedIR
-*.LS_SqlServer_DEV   # Exclude this linked service
-*.*@testFolder       # Exclude all objects in testFolder
```

> File must be UTF-8 encoded

## See Also

- [Publishing Workflow](PUBLISHING.md)
- [Configuration & Environment Replacement](CONFIGURATION.md)
- [Selective Deployment Logic Matrix](SELECTIVE_DEPLOYMENT.md)
- [Incremental Deployment](INCREMENTAL_DEPLOYMENT.md)

---

[← Back to Main Documentation](../../README.md)
