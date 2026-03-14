# Incremental Deployment

**Related:** [Publishing Workflow](PUBLISHING.md) | [Selective Deployment](SELECTIVE_DEPLOYMENT.md) | [Main Documentation](../../README.md)

## Overview

Incremental deployment speeds up CI/CD pipelines by deploying **only changed objects** instead of the entire ADF. This is especially valuable for large data factories with hundreds of objects.

> **Status**: Available since v1.4 (preview). Since v1.10, uses Azure Storage instead of ADF Global Parameters.

## How It Works

Incremental deployment maintains a **deployment state file** in Azure Storage containing MD5 hashes of all deployed objects. During deployment:

1. **Load previous state** from Storage (MD5 hashes of last deployment)
2. **Calculate hashes** of current objects from source
3. **Compare** - identify changed objects only
4. **Deploy** - only changed objects
5. **Update state** - save new hashes to Storage

### Deployment State File

Located in Azure Storage as JSON:
```
{ADFName}.adftools_deployment_state.json
```

Contents:
```json
{
  "pipeline.PL_CopyData": "a1b2c3d4e5f6...",
  "pipeline.PL_Transform": "f6e5d4c3b2a1...",
  "linkedService.LS_KeyVault": "b2c3d4e5f6a1...",
  ...
}
```

## Enable Incremental Deployment

### Step 1: Prepare Azure Storage

You need a Azure Storage Account with a file share accessible to your deployment agent.

```
Storage Account: mydftools
File Share: adftools
Path: https://mydftools.file.core.windows.net/adftools
```

### Step 2: Create Publish Option

```powershell
$opt = New-AdfPublishOption
$opt.IncrementalDeployment = $true
$opt.IncrementalDeploymentStorageUri = 'https://mydftools.file.core.windows.net/adftools'
```

### Step 3: Deploy with Publish Option

```powershell
Publish-AdfV2FromJson `
    -RootFolder $RootFolder `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Location $Location `
    -Option $opt
```

**First run:** All objects deploy (no previous state exists)  
**Subsequent runs:** Only changed objects deploy

## Example: Complete Setup

```powershell
# Configuration
$StorageUri = 'https://adftools.file.core.windows.net/deployment'
$RootFolder = 'c:\GitHub\MyADF\'
$ResourceGroupName = 'rg-production'
$DataFactoryName = 'adf-production'
$Location = 'NorthEurope'

# Create publish option with incremental deployment
$opt = New-AdfPublishOption
$opt.IncrementalDeployment = $true
$opt.IncrementalDeploymentStorageUri = $StorageUri

# Deploy - only changed objects will be deployed
Publish-AdfV2FromJson `
    -RootFolder $RootFolder `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Location $Location `
    -Option $opt
```

## Performance Improvement

**Without Incremental Deployment** (100 objects):
- Load 100 objects: 5s
- Deploy 100 objects: 30s
- Total: ~35s

**With Incremental Deployment** (only 5 changed):
- Load 100 objects: 5s
- Deploy 5 objects: 1.5s
- Total: ~6.5s

**Typical savings**: 80-90% faster when few objects change

## Important Considerations

### ⚠️ Prerequisites

Both of these must be true for incremental deployment to work:
- `IncrementalDeployment = true`
- `IncrementalDeploymentStorageUri` is not empty

If `IncrementalDeploymentStorageUri` is empty, you'll see a warning and incremental mode is disabled.

### 🔄 How Changes Are Detected

Objects are compared using **MD5 hashing**:
- Hash is calculated **after configuration replacement**
- If you change config values → object is marked as changed
- If only comments change → object may still be flagged if whitespace differs

### ⚠️ Manual Changes Break Incremental Deployment

**Critical assumption**: No one modifies ADF objects manually in Azure.

If someone manually edits a pipeline in the Azure Portal:
- Hashes will mismatch next deployment
- Object will be marked as "changed" and redeployed
- Manual changes are overwritten

### Redeploy Everything

If you need to force a full redeployment:

**Option 1**: Temporarily disable incremental mode
```powershell
# Set IncrementalDeployment = false
$opt.IncrementalDeployment = $false
# Deploy everything again
```

**Option 2**: Delete the deployment state file
```powershell
# Manually delete .adftools_deployment_state.json from Storage
# Next deployment will treat as first deployment
```

## Combining with Other Options

### Incremental + Selective Deployment

Deploy only changed pipelines:

```powershell
$opt = New-AdfPublishOption

# Enable incremental (only changed objects)
$opt.IncrementalDeployment = $true
$opt.IncrementalDeploymentStorageUri = 'https://...

# Enable selective (only pipelines)
$opt.Includes.Add('pipeline.*', '')

# Result: Only CHANGED pipelines are deployed
```

### Incremental + Configuration Replacement

```powershell
Publish-AdfV2FromJson `
    -RootFolder $RootFolder `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Location $Location `
    -Stage 'PROD' `
    -Option $opt

# Hash is calculated AFTER config replacement
# Changing config values = object marked as changed = redeployed
```

### Incremental + Deletion

```powershell
$opt = New-AdfPublishOption
$opt.IncrementalDeployment = $true
$opt.IncrementalDeploymentStorageUri = 'https://...'
$opt.DeleteNotInSource = $true   # Also delete removed objects

# Result: Deploy changed objects + delete missing objects
```

## Troubleshooting

### Incremental Mode Not Working

**Symptom**: All objects redeployed every time  
**Causes**:
1. `IncrementalDeploymentStorageUri` is empty
2. Storage file doesn't have read/write permissions
3. Previous state file is corrupted

**Solution**:
- Verify `IncrementalDeploymentStorageUri` is set correctly
- Check storage account permissions
- Delete and recreate deployment state file

### Objects Not Being Updated

**Symptom**: Changes don't appear in deployed ADF  
**Causes**:
1. Hash calculation uses previous config values
2. Someone manually edited the object in Azure
3. Whitespace/formatting differences

**Solution**:
1. Update config, redeploy (hash will change)
2. Set `IncrementalDeployment = false` to force full deployment
3. Check file formatting (UTF-8 encoding, line endings)

### Storage Connection Issues

**Error**: "Cannot connect to storage"  
**Solution**:
- Verify storage URI format: `https://account.file.core.windows.net/share`
- Check network access (firewall rules)
- Verify storage account credentials
- Ensure deployment agent has network access to storage

## Best Practices

✅ **DO**:
- Use incremental deployment in CI/CD pipelines (saves time)
- Combine with configuration files (changes trigger redeploy)
- Test on non-production first
- Keep deployment agents restricted to code changes only

❌ **DON'T**:
- Manually edit ADF objects in Azure while using incremental deployment
- Share storage state between different ADF instances (use unique storage paths)
- Assume incremental mode works without verifying storage connection
- Delete state file without understanding the consequences

## See Also

- [Publishing Workflow](PUBLISHING.md)
- [Publish Options - Filtering & Controls](PUBLISH_OPTIONS.md)
- [Selective Deployment - Advanced Options](SELECTIVE_DEPLOYMENT.md)

---

[← Back to Main Documentation](../../README.md)
