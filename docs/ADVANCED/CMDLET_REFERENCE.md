# Cmdlet Reference

**Related:** [Publishing Workflow](../GUIDE/PUBLISHING.md) | [Main Documentation](../../README.md)

## Core Functions

### Publish-AdfV2FromJson

Main cmdlet for deploying ADF from JSON files.

**Syntax:**
```powershell
Publish-AdfV2FromJson `
    -RootFolder <String> `
    -ResourceGroupName <String> `
    -DataFactoryName <String> `
    -Location <String> `
    [-Stage <String>] `
    [-Option <AdfPublishOption>] `
    [-Method <String>] `
    [-DryRun]
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| RootFolder | String | Yes | Path to ADF code folder |
| ResourceGroupName | String | Yes | Azure resource group name |
| DataFactoryName | String | Yes | ADF instance name |
| Location | String | Yes | Azure region (e.g., 'NorthEurope') |
| Stage | String | No | Stage name for config replacement (UAT, PROD) or full path to config file |
| Option | AdfPublishOption | No | Publish options object (filtering, triggers, etc.) |
| Method | String | No | Publishing method: 'AzDataFactory' or 'AzResource' (default) |
| DryRun | Switch | No | Validate without deploying |

**Returns:** AdfPublishOption (deployment result)

**Example:**
```powershell
Publish-AdfV2FromJson -RootFolder 'c:\MyADF' `
  -ResourceGroupName 'rg-prod' `
  -DataFactoryName 'adf-prod' `
  -Location 'NorthEurope' `
  -Stage 'PROD'
```

---

### Import-AdfFromFolder

Loads ADF objects from JSON files into memory.

**Syntax:**
```powershell
Import-AdfFromFolder `
    -RootFolder <String> `
    -FactoryName <String>
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| RootFolder | String | Path to ADF code folder |
| FactoryName | String | ADF instance name (for identification) |

**Returns:** Adf (ADF instance object)

**Example:**
```powershell
$adf = Import-AdfFromFolder -RootFolder 'c:\MyADF' -FactoryName 'MyADF'
```

---

### Test-AdfCode

Validates ADF code before deployment.

**Syntax:**
```powershell
Test-AdfCode -RootFolder <String>
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| RootFolder | String | Path to ADF code folder |

**Returns:** Int (number of errors found)

**Example:**
```powershell
$errors = Test-AdfCode -RootFolder 'c:\MyADF'
if ($errors -gt 0) { 
  Write-Host "Fix $errors errors before deploying"
}
```

---

## Options Functions

### New-AdfPublishOption

Creates a new publish options object.

**Syntax:**
```powershell
New-AdfPublishOption [[-FilterFilePath] <String>]
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| FilterFilePath | String | Optional path to filter rules file |

**Returns:** AdfPublishOption

**Example:**
```powershell
$opt = New-AdfPublishOption
$opt = New-AdfPublishOption -FilterFilePath '.\rules.txt'
```

---

## AdfPublishOption Properties

Configuration object for deployment behavior.

**Properties:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| Includes | Hashtable | Empty | Objects to deploy (whitelist) |
| Excludes | Hashtable | Empty | Objects to exclude (blacklist) |
| DeleteNotInSource | Boolean | false | Delete objects not in source |
| StopStartTriggers | Boolean | true | Stop/start triggers during deployment |
| CreateNewInstance | Boolean | true | Create ADF if doesn't exist |
| DeployGlobalParams | Boolean | true | Deploy global parameters |
| FailsWhenConfigItemNotFound | Boolean | true | Fail if config item missing |
| FailsWhenPathNotFound | Boolean | true | Fail if config path missing |
| DoNotStopStartExcludedTriggers | Boolean | false | Don't stop excluded triggers |
| DoNotDeleteExcludedObjects | Boolean | true | Protect excluded objects from deletion |
| IncrementalDeployment | Boolean | false | Deploy only changed objects |
| IncrementalDeploymentStorageUri | String | (empty) | Storage path for deployment state |
| TriggerStopMethod | Enum | AllEnabled | Which triggers to stop: AllEnabled, DeployableOnly |
| TriggerStartMethod | Enum | BasedOnSourceCode | How to start: BasedOnSourceCode, KeepPreviousState |

---

## Object Functions

### Get-AdfObjectByName

Retrieves a single ADF object by name.

**Syntax:**
```powershell
$adf | Get-AdfObjectByName -Name <String> -Type <String>
```

**Example:**
```powershell
$pipeline = $adf | Get-AdfObjectByName -Name 'PL_Main' -Type 'pipeline'
```

---

### Get-AdfObjectByPattern

Retrieves ADF objects matching a wildcard pattern.

**Syntax:**
```powershell
$adf | Get-AdfObjectByPattern -Pattern <String>
```

**Example:**
```powershell
$pipelines = $adf | Get-AdfObjectByPattern -Pattern 'pipeline.Copy*'
```

---

### Get-AdfObjectsByFolderName

Retrieves all objects in a specific ADF folder.

**Syntax:**
```powershell
$adf | Get-AdfObjectsByFolderName -FolderName <String>
```

**Example:**
```powershell
$etlObjects = $adf | Get-AdfObjectsByFolderName -FolderName 'ETL'
```

---

## Feature Functions

### Export-AdfToArmTemplate

Exports ADF objects to ARM template format.

**Syntax:**
```powershell
Export-AdfToArmTemplate `
    -AdfInstance <Adf> `
    -OutputPath <String>
```

**Example:**
```powershell
$adf = Import-AdfFromFolder -RootFolder 'c:\MyADF'
Export-AdfToArmTemplate -AdfInstance $adf -OutputPath 'c:\output'
```

---

### Test-AdfLinkedServiceConnection

Tests a linked service connection.

**Syntax:**
```powershell
Test-AdfLinkedServiceConnection `
    -ResourceGroupName <String> `
    -DataFactoryName <String> `
    -LinkedServiceName <String>
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| ResourceGroupName | String | Azure resource group |
| DataFactoryName | String | ADF instance name |
| LinkedServiceName | String | Linked service name to test |
| TenantId | String | (Optional) Tenant ID for SPN auth |
| Credential | PSCredential | (Optional) Service Principal credential |

**Returns:** Boolean

**Example:**
```powershell
$result = Test-AdfLinkedServiceConnection `
    -ResourceGroupName 'rg-prod' `
    -DataFactoryName 'adf-prod' `
    -LinkedServiceName 'LS_SqlServer'

if ($result) { Write-Host "✓ Connection OK" }
```

---

### Get-AdfObjectsDependenciesMermaidDiagram

Generates Mermaid diagram of object dependencies.

**Syntax:**
```powershell
Get-AdfObjectsDependenciesMermaidDiagram -AdfInstance <Adf>
```

**Returns:** String (Mermaid markup)

**Example:**
```powershell
$adf = Import-AdfFromFolder -RootFolder 'c:\MyADF'
$diagram = Get-AdfObjectsDependenciesMermaidDiagram -AdfInstance $adf
$diagram | Out-File 'diagram.md'
```

---

## Enum Values

### TriggerStopMethod

```powershell
[TriggerStopMethod]::AllEnabled      # Stop all active triggers
[TriggerStopMethod]::DeployableOnly  # Stop only triggers being deployed
```

### TriggerStartMethod

```powershell
[TriggerStartMethod]::BasedOnSourceCode  # Use source file status
[TriggerStartMethod]::KeepPreviousState  # Restore previous state
```

---

## Examples

### Minimal Deployment

```powershell
Import-Module azure.datafactory.tools

Publish-AdfV2FromJson `
    -RootFolder 'c:\MyADF' `
    -ResourceGroupName 'rg-prod' `
    -DataFactoryName 'adf-prod' `
    -Location 'NorthEurope'
```

### With Options

```powershell
$opt = New-AdfPublishOption
$opt.Includes.Add('pipeline.*', '')
$opt.DeleteNotInSource = $true
$opt.TriggerStopMethod = 'DeployableOnly'

Publish-AdfV2FromJson `
    -RootFolder 'c:\MyADF' `
    -ResourceGroupName 'rg-prod' `
    -DataFactoryName 'adf-prod' `
    -Location 'NorthEurope' `
    -Option $opt
```

### With Configuration

```powershell
Publish-AdfV2FromJson `
    -RootFolder 'c:\MyADF' `
    -ResourceGroupName 'rg-prod' `
    -DataFactoryName 'adf-prod' `
    -Location 'NorthEurope' `
    -Stage 'PROD'
```

### With Incremental Deployment

```powershell
$opt = New-AdfPublishOption
$opt.IncrementalDeployment = $true
$opt.IncrementalDeploymentStorageUri = 'https://storage.file.core.windows.net/adftools'

Publish-AdfV2FromJson `
    -RootFolder 'c:\MyADF' `
    -ResourceGroupName 'rg-prod' `
    -DataFactoryName 'adf-prod' `
    -Location 'NorthEurope' `
    -Option $opt
```

### Complete Validation & Deploy

```powershell
Import-Module azure.datafactory.tools

# Step 1: Validate
$errors = Test-AdfCode -RootFolder 'c:\MyADF'
if ($errors -gt 0) { exit 1 }

# Step 2: Test connections
$adf = Import-AdfFromFolder -RootFolder 'c:\MyADF' -FactoryName 'MyADF'
foreach ($ls in $adf.linkedServices) {
    $result = Test-AdfLinkedServiceConnection `
        -ResourceGroupName 'rg-prod' `
        -DataFactoryName 'adf-prod' `
        -LinkedServiceName $ls.Name
    if (-not $result) { exit 1 }
}

# Step 3: Deploy
Publish-AdfV2FromJson `
    -RootFolder 'c:\MyADF' `
    -ResourceGroupName 'rg-prod' `
    -DataFactoryName 'adf-prod' `
    -Location 'NorthEurope'
```

---

## See Also

- [Publishing Workflow](../GUIDE/PUBLISHING.md)
- [Publish Options](../GUIDE/PUBLISH_OPTIONS.md)
- [Configuration](../GUIDE/CONFIGURATION.md)

---

[← Back to Main Documentation](../../README.md)
