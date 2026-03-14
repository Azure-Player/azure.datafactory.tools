# Test Linked Service Connections

**Related:** [Build & Test](BUILD_AND_TEST.md) | [Main Documentation](../../README.md)

## Overview

The `Test-AdfLinkedServiceConnection` cmdlet (preview) automates testing of linked service connections. This replaces the manual "Test connection" operation in the Azure Portal UI.

> **Note:** This feature uses an undocumented ADF API and is in preview.

## Requirements

- Azure.DataFactory PowerShell module
- Service Principal (SPN) for authentication, OR
- Current Az PowerShell context (already authenticated)
- Network access to target services

## Test Connection with Service Principal

### Setup

You need a Service Principal (App Registration) with permissions to your Data Factory.

```powershell
# Parameters
$TenantId = 'your-tenant-id'
$ClientId = 'your-app-id'
$ClientSecret = 'your-app-secret'
$ResourceGroupName = 'rg-datafactory'
$DataFactoryName = 'adf-production'
$LinkedServiceName = 'LS_AzureKeyVault'

# Create credential
$credential = New-Object System.Management.Automation.PSCredential(
    $ClientId,
    (ConvertTo-SecureString $ClientSecret -AsPlainText -Force)
)

# Test connection
$result = Test-AdfLinkedServiceConnection `
    -TenantId $TenantId `
    -Credential $credential `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -LinkedServiceName $LinkedServiceName

Write-Host "Connection test result: $result"
```

## Test Connection with Current Context

If you're already authenticated with Az PowerShell:

```powershell
$result = Test-AdfLinkedServiceConnection `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -LinkedServiceName $LinkedServiceName

if ($result -eq $true) {
    Write-Host "✓ Connection successful"
} else {
    Write-Host "✗ Connection failed"
}
```

## Complete Example

### Azure DevOps Pipeline

```yaml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

variables:
  TENANT_ID: $(TenantId)
  CLIENT_ID: $(ClientId)
  CLIENT_SECRET: $(ClientSecret)
  RESOURCE_GROUP: 'rg-prod-adf'
  DATA_FACTORY: 'adf-production'

steps:
  - task: PowerShell@2
    displayName: 'Test Linked Connections'
    inputs:
      targetType: 'inline'
      script: |
        Import-Module -Name azure.datafactory.tools
        
        $credential = New-Object System.Management.Automation.PSCredential(
            '$(CLIENT_ID)',
            (ConvertTo-SecureString '$(CLIENT_SECRET)' -AsPlainText -Force)
        )
        
        # Test multiple connections
        $linkedServices = @(
            'LS_AzureKeyVault',
            'LS_SqlDatabase',
            'LS_BlobStorage'
        )
        
        foreach ($ls in $linkedServices) {
            $result = Test-AdfLinkedServiceConnection `
                -TenantId '$(TENANT_ID)' `
                -Credential $credential `
                -ResourceGroupName '$(RESOURCE_GROUP)' `
                -DataFactoryName '$(DATA_FACTORY)' `
                -LinkedServiceName $ls
            
            if ($result) {
                Write-Host "✓ $ls: Connection successful"
            } else {
                Write-Host "✗ $ls: Connection failed"
                exit 1
            }
        }

  - task: PowerShell@2
    displayName: 'Deploy ADF'
    condition: succeeded()
    inputs:
      targetType: 'inline'
      script: |
        # Deployment script here
```

## Common Linked Services to Test

### Azure SQL Database

```powershell
Test-AdfLinkedServiceConnection `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -LinkedServiceName 'LS_SqlServer'
```

### Azure Blob Storage

```powershell
Test-AdfLinkedServiceConnection `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -LinkedServiceName 'LS_BlobStorage'
```

### Azure Key Vault

```powershell
Test-AdfLinkedServiceConnection `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -LinkedServiceName 'LS_AzureKeyVault'
```

### Azure Data Lake Storage Gen2

```powershell
Test-AdfLinkedServiceConnection `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -LinkedServiceName 'LS_ADLS'
```

## Testing Multiple Connections

### Loop Through All Linked Services

```powershell
# Load ADF from source
$adf = Import-AdfFromFolder -RootFolder $RootFolder -FactoryName $DataFactoryName

# Get all linked services
$linkedServices = $adf.linkedServices

$failedTests = @()

foreach ($ls in $linkedServices) {
    Write-Host "Testing: $($ls.Name)..."
    
    try {
        $result = Test-AdfLinkedServiceConnection `
            -ResourceGroupName $ResourceGroupName `
            -DataFactoryName $DataFactoryName `
            -LinkedServiceName $ls.Name
        
        if ($result) {
            Write-Host "  ✓ Success"
        } else {
            Write-Host "  ✗ Failed"
            $failedTests += $ls.Name
        }
    } catch {
        Write-Host "  ⚠ Error: $_"
        $failedTests += $ls.Name
    }
}

if ($failedTests.Count -gt 0) {
    Write-Host "`n❌ Failed connections: $($failedTests -join ', ')"
    exit 1
} else {
    Write-Host "`n✅ All connections successful"
}
```

## Troubleshooting

### Connection Test Fails

**Symptom:** Test returns false  
**Possible Causes**:
- Linked service credentials are incorrect
- Network connectivity issues
- Target service is down
- Firewall blocks connection

**Solution**:
1. Manually test connection in Azure Portal UI
2. Verify credentials are correct
3. Check network/firewall rules
4. Ensure target service is accessible

### Authentication Fails

**Error:** Unauthorized (401)  
**Causes**:
- Service Principal doesn't have permissions
- Credentials are incorrect
- Az context is not authenticated

**Solution**:
```powershell
# Verify authentication
Get-AzContext

# If needed, login manually
Connect-AzAccount -Tenant $TenantId -ServicePrincipal `
    -Credential $credential
```

### API Not Available

**Error:** "Test connection API not available"  
**Cause**: Using older version of Az.DataFactory

**Solution**:
```powershell
Update-Module -Name Az.DataFactory -Force
```

## Pre-Deployment Connection Testing

```powershell
# 1. Load ADF code
$adf = Import-AdfFromFolder -RootFolder $RootFolder -FactoryName $DataFactoryName

# 2. Test all connections
$linkedServices = $adf.linkedServices
foreach ($ls in $linkedServices) {
    $result = Test-AdfLinkedServiceConnection `
        -ResourceGroupName $ResourceGroupName `
        -DataFactoryName $DataFactoryName `
        -LinkedServiceName $ls.Name
    
    if (-not $result) {
        Write-Error "Connection test failed for: $($ls.Name)"
        exit 1
    }
}

# 3. If all tests pass, proceed with deployment
Publish-AdfV2FromJson `
    -RootFolder $RootFolder `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Location $Location
```

## See Also

- [Build & Test Code](BUILD_AND_TEST.md)
- [Publishing Workflow](../GUIDE/PUBLISHING.md)

---

[← Back to Main Documentation](../../README.md)
