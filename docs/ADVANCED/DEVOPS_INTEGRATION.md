# Azure DevOps Integration

**Related:** [Publishing Workflow](../GUIDE/PUBLISHING.md) | [Main Documentation](../../README.md)

## Overview

Integrate **azure.datafactory.tools** into your Azure DevOps CI/CD pipeline to automate ADF deployments across environments (DEV → TEST → PROD).

## Prerequisites

- Azure DevOps project with Git repository
- ADF code committed to repository (collaboration branch)
- Service connection to Azure subscription
- Sufficient permissions to create/modify ADF instances

## Quick Start Pipeline

### Minimal Pipeline Example

```yaml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

variables:
  AZURE_DATAFACTORY: 'adf-production'
  RESOURCE_GROUP: 'rg-production'
  LOCATION: 'North Europe'

steps:
  - checkout: self

  - task: PowerShell@2
    displayName: 'Install Module'
    inputs:
      targetType: 'inline'
      script: |
        Install-Module -Name azure.datafactory.tools -Force -Scope CurrentUser

  - task: AzureResourceManagerTemplateDeployment@3
    displayName: 'Deploy ADF'
    inputs:
      connectedServiceNameARM: 'Azure Production'
      subscriptionId: '$(SubscriptionId)'
      action: 'Create Or Update Resource Group'
      resourceGroupName: '$(RESOURCE_GROUP)'
      location: '$(LOCATION)'

  - task: PowerShell@2
    displayName: 'Publish ADF Code'
    inputs:
      targetType: 'inline'
      script: |
        Import-Module -Name azure.datafactory.tools
        
        $RootFolder = '$(Build.SourcesDirectory)\ADF'
        
        Publish-AdfV2FromJson `
            -RootFolder $RootFolder `
            -ResourceGroupName '$(RESOURCE_GROUP)' `
            -DataFactoryName '$(AZURE_DATAFACTORY)' `
            -Location '$(LOCATION)' `
            -Stage 'PROD'
```

## Multi-Stage Pipeline

Recommended pipeline structure for DEV, TEST, PROD environments:

```yaml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

stages:
  - stage: Validate
    displayName: 'Validate & Test'
    jobs:
      - job: ValidateCode
        displayName: 'Code Validation'
        steps:
          - checkout: self

          - task: PowerShell@2
            displayName: 'Install Module'
            inputs:
              targetType: 'inline'
              script: |
                Install-Module -Name azure.datafactory.tools -Force

          - task: PowerShell@2
            displayName: 'Test ADF Code'
            inputs:
              targetType: 'inline'
              script: |
                Import-Module -Name azure.datafactory.tools
                
                $errors = Test-AdfCode -RootFolder '$(Build.SourcesDirectory)\ADF'
                
                if ($errors -gt 0) {
                  Write-Host "##vso[task.logissue type=error]Code validation failed with $errors errors"
                  exit 1
                }

  - stage: DeployDev
    displayName: 'Deploy to Dev'
    dependsOn: Validate
    condition: succeeded()
    variables:
      AZURE_DATAFACTORY: 'adf-dev'
      RESOURCE_GROUP: 'rg-adf-dev'
    jobs:
      - deployment: DeployADF
        displayName: 'Deploy to Dev'
        environment: 'Development'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self

                - task: PowerShell@2
                  displayName: 'Install Module'
                  inputs:
                    targetType: 'inline'
                    script: |
                      Install-Module -Name azure.datafactory.tools -Force

                - task: AzureResourceManagerTemplateDeployment@3
                  displayName: 'Create ADF'
                  inputs:
                    connectedServiceNameARM: 'Azure Dev'
                    subscriptionId: '$(DevSubscriptionId)'
                    action: 'Create Or Update Resource Group'
                    resourceGroupName: '$(RESOURCE_GROUP)'
                    location: 'North Europe'

                - task: PowerShell@2
                  displayName: 'Publish ADF Code'
                  inputs:
                    targetType: 'inline'
                    script: |
                      Import-Module -Name azure.datafactory.tools
                      
                      $RootFolder = '$(Pipeline.Workspace)\s\ADF'
                      
                      Publish-AdfV2FromJson `
                          -RootFolder $RootFolder `
                          -ResourceGroupName '$(RESOURCE_GROUP)' `
                          -DataFactoryName '$(AZURE_DATAFACTORY)' `
                          -Location 'North Europe' `
                          -Stage 'DEV'

  - stage: DeployTest
    displayName: 'Deploy to Test'
    dependsOn: DeployDev
    condition: succeeded()
    variables:
      AZURE_DATAFACTORY: 'adf-test'
      RESOURCE_GROUP: 'rg-adf-test'
    jobs:
      - deployment: DeployADF
        displayName: 'Deploy to Test'
        environment: 'Testing'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self

                - task: PowerShell@2
                  displayName: 'Install Module'
                  inputs:
                    targetType: 'inline'
                    script: |
                      Install-Module -Name azure.datafactory.tools -Force

                - task: PowerShell@2
                  displayName: 'Publish ADF Code'
                  inputs:
                    targetType: 'inline'
                    script: |
                      Import-Module -Name azure.datafactory.tools
                      
                      Publish-AdfV2FromJson `
                          -RootFolder '$(Pipeline.Workspace)\s\ADF' `
                          -ResourceGroupName '$(RESOURCE_GROUP)' `
                          -DataFactoryName '$(AZURE_DATAFACTORY)' `
                          -Location 'North Europe' `
                          -Stage 'TEST'

  - stage: DeployProd
    displayName: 'Deploy to Production'
    dependsOn: DeployTest
    condition: succeeded()
    variables:
      AZURE_DATAFACTORY: 'adf-prod'
      RESOURCE_GROUP: 'rg-adf-prod'
    jobs:
      - deployment: DeployADF
        displayName: 'Deploy to Production'
        environment: 'Production'  # Adds approval gate
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self

                - task: PowerShell@2
                  displayName: 'Install Module'
                  inputs:
                    targetType: 'inline'
                    script: |
                      Install-Module -Name azure.datafactory.tools -Force

                - task: PowerShell@2
                  displayName: 'Publish ADF Code'
                  inputs:
                    targetType: 'inline'
                    script: |
                      Import-Module -Name azure.datafactory.tools
                      
                      $opt = New-AdfPublishOption
                      $opt.IncrementalDeployment = $true
                      $opt.IncrementalDeploymentStorageUri = '$(IncDeployStorageUri)'
                      
                      Publish-AdfV2FromJson `
                          -RootFolder '$(Pipeline.Workspace)\s\ADF' `
                          -ResourceGroupName '$(RESOURCE_GROUP)' `
                          -DataFactoryName '$(AZURE_DATAFACTORY)' `
                          -Location 'North Europe' `
                          -Stage 'PROD' `
                          -Option $opt
```

## Configuration Setup

### Service Connection

Create service connection for Azure subscription:

1. Go to **Project Settings** → **Service Connections**
2. Click **New Service Connection** → **Azure Resource Manager**
3. Choose **Service Principal (automatic)**
4. Select subscription and create connection
5. Name it `Azure Production` (or similar)

### Pipeline Variables

Define variables at pipeline or stage level:

```yaml
variables:
  IncDeployStorageUri: 'https://adftools.file.core.windows.net/deployment'
  
  # Dev environment
  DevSubscriptionId: 'YOUR-DEV-SUBSCRIPTION-ID'
  
  # Prod environment  
  ProdSubscriptionId: 'YOUR-PROD-SUBSCRIPTION-ID'
```

Store sensitive values as **secret variables**:
- Click pipeline → **Edit**
- Variables section → **New variable** (if not exists)
- Toggle **Keep this value secret**
- Save

## Incremental Deployment in CI/CD

Use incremental deployment to speed up production deployments:

```powershell
$opt = New-AdfPublishOption
$opt.IncrementalDeployment = $true
$opt.IncrementalDeploymentStorageUri = '$(IncDeployStorageUri)'

Publish-AdfV2FromJson `
    -RootFolder $RootFolder `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Location $Location `
    -Stage 'PROD' `
    -Option $opt
```

**First run:** Deploys all objects  
**Subsequent runs:** Only changed objects deployed  
**Savings:** 60-90% faster typical deployments

## Approval Gates

Add approval step before production deployment:

In stage definition:
```yaml
- stage: DeployProd
  environment: 'Production'  # Requires approval
  jobs:
    - deployment: DeployADF
      # ...
```

### Manual Approval Process

1. Pipeline runs validation and dev/test stages
2. Reaches production stage
3. **Waits for approval** (shows notification)
4. Approver reviews and approves/rejects
5. If approved, production deployment runs

## Error Handling & Notifications

### Fail Fast on Errors

```powershell
$ErrorActionPreference = 'Stop'

try {
    Publish-AdfV2FromJson `
        -RootFolder $RootFolder `
        -ResourceGroupName $ResourceGroupName `
        -DataFactoryName $DataFactoryName `
        -Location $Location
} catch {
    Write-Host "##vso[task.logissue type=error]Deployment failed: $_"
    exit 1
}
```

### Deployment Results Notification

```yaml
- task: PublishBuildArtifacts@1
  displayName: 'Publish Deployment Report'
  condition: always()
  inputs:
    pathToPublish: '$(Build.ArtifactStagingDirectory)'
    artifactName: 'deployment-report'

- task: SendEmail@1
  displayName: 'Send Status Email'
  condition: failed()
  inputs:
    To: 'team@company.com'
    Subject: 'ADF Deployment Failed'
    Body: 'See build for details: $(Build.BuildUri)'
```

## Common Patterns

### Blue-Green Deployment

Maintain two ADF instances and switch traffic:

```yaml
variables:
  BLUE_ADF: 'adf-blue'
  GREEN_ADF: 'adf-green'

# Deploy to Green
# Test
# Switch production traffic from Blue to Green
```

### Canary Deployment

Deploy to small subset first:

```yaml
stages:
  - stage: DeployCanary
    displayName: 'Deploy to Canary (10%)'
    
  - stage: DeployFull
    displayName: 'Deploy to Production (100%)'
    dependsOn: DeployCanary
```

## Troubleshooting

### Module Not Found

**Error:** "Could not find module azure.datafactory.tools"  
**Solution:**
```yaml
- task: PowerShell@2
  inputs:
    script: |
      Install-Module -Name azure.datafactory.tools -Force -Scope CurrentUser
```

### Authentication Failures

**Error:** "Unauthorized: Service Principal"  
**Solution**:
1. Verify service connection is correct
2. Check Service Principal permissions in subscription
3. Ensure subscription ID matches in variables

### Deployment Timeout

**Error:** "task timeout after 1800 seconds"  
**Solution**:
```yaml
- task: PowerShell@2
  timeoutInMinutes: 120  # Increase timeout
```

## See Also

- [Publishing Workflow](../GUIDE/PUBLISHING.md)
- [Publish Options](../GUIDE/PUBLISH_OPTIONS.md)
- [Configuration & Stages](../GUIDE/CONFIGURATION.md)
- [Incremental Deployment](../GUIDE/INCREMENTAL_DEPLOYMENT.md)

---

[← Back to Main Documentation](../../README.md)
