# Build and Test ADF Code

**Related:** [Publishing Workflow](../GUIDE/PUBLISHING.md) | [Main Documentation](../../README.md)

## Overview

The `Test-AdfCode` cmdlet validates your ADF code before deployment, catching errors early in your development cycle.

## Running Tests

### Basic Usage

```powershell
Test-AdfCode -RootFolder $RootFolder
```

Returns the number of errors found (0 = all good).

### Example

```powershell
$RootFolder = 'c:\GitHub\MyADF\'
$result = Test-AdfCode -RootFolder $RootFolder

Write-Host "Validation complete. Errors found: $result"
if ($result -gt 0) {
    Write-Host "Fix errors before deploying!"
    exit 1
}
```

## Validation Checks

The cmdlet performs the following validations:

### 1. JSON Format Validation
- Reads all JSON files in subfolders
- Validates JSON syntax
- Reports malformed JSON

**Error Example:**
```
ERROR: File 'pipeline\PL_Invalid.json' has invalid JSON format
Unexpected token '}' at position 245
```

### 2. Dependency Validation
- Checks that all referenced objects exist
- Validates linked service references
- Validates dataset references

**Error Example:**
```
ERROR: Pipeline 'PL_CopyData' references dataset 'DS_Missing' which does not exist
```

### 3. File Name Validation
- Ensures JSON file name matches object name inside
- Prevents naming mismatches

**Error Example:**
```
ERROR: File 'pipeline\PL_Copy.json' contains object named 'PL_CopyData' (name mismatch)
```

### 4. Additional Checks
- More validations coming soon...

## Using Test-AdfCode in CI/CD

### Azure DevOps Pipeline Example

```yaml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

steps:
  - checkout: self

  - task: PowerShell@2
    displayName: 'Test ADF Code'
    inputs:
      targetType: 'inline'
      script: |
        Import-Module -Name azure.datafactory.tools
        
        $RootFolder = '$(System.DefaultWorkingDirectory)/MyADF'
        $errors = Test-AdfCode -RootFolder $RootFolder
        
        if ($errors -gt 0) {
          Write-Host "##vso[task.logissue type=error]Code validation failed with $errors errors"
          exit 1
        }

  - task: PowerShell@2
    displayName: 'Deploy ADF'
    condition: succeeded()
    inputs:
      targetType: 'inline'
      script: |
        # Deployment script here
```

### GitHub Actions Example

```yaml
name: Test and Deploy ADF

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install Module
        shell: pwsh
        run: |
          Install-Module -Name azure.datafactory.tools -Force

      - name: Test ADF Code
        shell: pwsh
        run: |
          $errors = Test-AdfCode -RootFolder 'MyADF'
          if ($errors -gt 0) {
            exit 1
          }

      - name: Deploy ADF
        if: success()
        shell: pwsh
        run: |
          # Deployment script here
```

## Common Issues and Solutions

### Issue: JSON Validation Fails

**Symptom:** Invalid JSON format error  
**Causes:**
- Missing comma between properties
- Unquoted strings
- Unescaped special characters
- Trailing comma in objects/arrays

**Solution:**
- Validate JSON syntax in VS Code (built-in support)
- Use online JSON validator
- Check for special characters in string values

### Issue: Dependency Not Found

**Symptom:** "Referenced object does not exist"  
**Causes:**
- Typo in object name
- Object file in wrong folder
- Object file name (without .json) doesn't match object name inside

**Solution:**
- Check object name spelling
- Verify file is in correct folder (linkedService, dataset, etc.)
- Ensure file name matches object name property

### Issue: File Name Mismatch

**Symptom:** "File name is different from object name"  
**Causes:**
- Renamed file but not object inside
- Manually edited file name

**Solution:**
- Rename file to match object name
- Update object name inside JSON to match file name

## Pre-Deployment Checklist

Before running `Publish-AdfV2FromJson`, run this quick check:

```powershell
# Test code first
$testErrors = Test-AdfCode -RootFolder $RootFolder
if ($testErrors -gt 0) {
    Write-Host "Fix validation errors first!"
    exit 1
}

# Then deploy
Publish-AdfV2FromJson `
    -RootFolder $RootFolder `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Location $Location
```

## See Also

- [Publishing Workflow](../GUIDE/PUBLISHING.md)
- [Configuration & Environment Values](../GUIDE/CONFIGURATION.md)

---

[← Back to Main Documentation](../../README.md)
