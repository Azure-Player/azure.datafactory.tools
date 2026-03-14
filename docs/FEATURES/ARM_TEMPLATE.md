# Export and Publish Using ARM Templates

**Related:** [Publishing Workflow](../GUIDE/PUBLISHING.md) | [Main Documentation](../../README.md)

## Overview

Azure Data Factory objects can be exported to **Azure Resource Manager (ARM) templates** for infrastructure-as-code deployments. This supports two workflows:

1. **Export ADF code to ARM Template** - Convert JSON objects to ARM template
2. **Publish ADF using ARM Template files** - Deploy from ARM templates instead of raw JSON

This approach integrates ADF deployment with Azure infrastructure management tools.

## Export ADF Code to ARM Template

Convert your ADF objects to ARM template format for deployment via Azure Resource Manager.

### Basic Usage

```powershell
$RootFolder = 'c:\GitHub\MyADF\'
$OutputFolder = 'c:\output\arm-templates\'

Export-AdfToArmTemplate `
    -RootFolder $RootFolder `
    -OutputPath $OutputFolder
```

### Output

Generates ARM template files:
```
arm-templates/
    template.json           # Main template
    parameters.json         # Default parameters
    parameters.dev.json     # Environment-specific (optional)
    parameters.prod.json    # Environment-specific (optional)
```

### Complete Example

```powershell
# Export
$adf = Import-AdfFromFolder -RootFolder 'c:\GitHub\MyADF\'

Export-AdfToArmTemplate `
    -AdfInstance $adf `
    -OutputPath 'c:\output\templates\'

# Deploy using Azure CLI
az deployment group create `
    --name adf-deployment `
    --resource-group rg-production `
    --template-file c:\output\templates\template.json `
    --parameters c:\output\templates\parameters.prod.json

# Or deploy using PowerShell
New-AzResourceGroupDeployment `
    -ResourceGroupName 'rg-production' `
    -TemplateFile 'c:\output\templates\template.json' `
    -TemplateParameterFile 'c:\output\templates\parameters.prod.json'
```

## Publish ADF Using ARM Template (Preview)

Deploy from ARM template files instead of raw JSON files.

### Setup

```powershell
$TemplateFolder = 'c:\GitHub\MyADF\arm-templates\'
$ResourceGroupName = 'rg-production'
$DataFactoryName = 'adf-production'
$Location = 'NorthEurope'
```

### Deploy from ARM Template

```powershell
Publish-AdfV2FromArmTemplate `
    -TemplateFolder $TemplateFolder `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Location $Location
```

### With Parameters File

```powershell
Publish-AdfV2FromArmTemplate `
    -TemplateFolder $TemplateFolder `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Location $Location `
    -ParametersFile 'parameters.prod.json'
```

## Limitations

The ARM Template export/publish has known limitations:

### Not Supported

- **Native CDC** (Change Data Capture) objects
- Some custom properties (see documentation)
- Certain data flow configurations
- Some trigger dependencies

### Known Issues

- Global Parameters may not export/import correctly
- Some linked service types have limited support
- Credentials might need special handling

## Workflow Comparison

### Traditional (JSON Files)
✅ Full feature support  
✅ Simple structure  
❌ No infrastructure parameters  
❌ Limited parameterization  

### ARM Templates
✅ Infrastructure-as-code approach  
✅ Parameter management  
✅ Integrates with Azure deployments  
❌ Some features not supported  
❌ More complex structure  

## Azure DevOps Pipeline Example

```yaml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

stages:
  - stage: Build
    displayName: 'Build and Export ARM Template'
    jobs:
      - job: ExportArmTemplate
        steps:
          - checkout: self

          - task: PowerShell@2
            displayName: 'Export to ARM Template'
            inputs:
              targetType: 'inline'
              script: |
                Import-Module -Name azure.datafactory.tools
                
                Export-AdfToArmTemplate `
                    -RootFolder '$(Build.SourcesDirectory)/MyADF' `
                    -OutputPath '$(Build.ArtifactStagingDirectory)/arm-templates'

          - task: PublishBuildArtifacts@1
            inputs:
              artifactName: 'arm-templates'

  - stage: DeployDev
    displayName: 'Deploy to Dev'
    dependsOn: Build
    jobs:
      - deployment: DeployADF
        environment: 'Dev'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: DownloadBuildArtifacts@0
                  inputs:
                    artifactName: 'arm-templates'

                - task: AzureResourceManagerTemplateDeployment@3
                  inputs:
                    deploymentScope: 'Resource Group'
                    azureResourceManagerConnection: 'Azure Dev'
                    subscriptionId: '$(DevSubscriptionId)'
                    action: 'Create Or Update Resource Group'
                    resourceGroupName: 'rg-adf-dev'
                    location: 'North Europe'
                    templateLocation: 'Linked artifact'
                    csmFile: '$(Pipeline.Workspace)/arm-templates/template.json'
                    csmParametersFile: '$(Pipeline.Workspace)/arm-templates/parameters.dev.json'
                    deploymentMode: 'Incremental'

  - stage: DeployProd
    displayName: 'Deploy to Prod'
    dependsOn: Build
    condition: succeeded()
    jobs:
      - deployment: DeployADF
        environment: 'Production'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: DownloadBuildArtifacts@0
                  inputs:
                    artifactName: 'arm-templates'

                - task: AzureResourceManagerTemplateDeployment@3
                  inputs:
                    deploymentScope: 'Resource Group'
                    azureResourceManagerConnection: 'Azure Prod'
                    subscriptionId: '$(ProdSubscriptionId)'
                    action: 'Create Or Update Resource Group'
                    resourceGroupName: 'rg-adf-prod'
                    location: 'North Europe'
                    templateLocation: 'Linked artifact'
                    csmFile: '$(Pipeline.Workspace)/arm-templates/template.json'
                    csmParametersFile: '$(Pipeline.Workspace)/arm-templates/parameters.prod.json'
                    deploymentMode: 'Incremental'
```

## Hybrid Approach: JSON + ARM Templates

You can combine both approaches:

```powershell
# 1. Deploy core infrastructure with ARM Template
New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile 'infrastructure.template.json'

# 2. Deploy ADF objects with traditional JSON method
Publish-AdfV2FromJson `
    -RootFolder $RootFolder `
    -ResourceGroupName $ResourceGroupName `
    -DataFactoryName $DataFactoryName `
    -Location $Location
```

## Troubleshooting

### Export Fails

**Error:** "Cannot export objects"  
**Causes**:
- Unsupported object types
- Invalid JSON in source files
- Missing dependencies

**Solution**:
1. Run `Test-AdfCode` to validate source
2. Check which objects are unsupported
3. Use traditional JSON deployment instead

### Deploy from ARM Template Fails

**Error:** "Deployment failed"  
**Common Causes**:
- Parameter values missing or invalid
- Linked service credentials not configured
- Resource already exists with different configuration

**Solution**:
1. Verify parameters file is correct
2. Check linked service setup
3. Use incremental deployment mode if updating

### Feature Not Supported

**Error:** "This object type is not supported"  
**Solution**:
- Export supported objects to ARM template
- Use traditional JSON deployment for unsupported objects
- Consider reporting as feature request

## See Also

- [Publishing Workflow](../GUIDE/PUBLISHING.md)
- [Configuration & Environment Values](../GUIDE/CONFIGURATION.md)
- [Build & Test Code](BUILD_AND_TEST.md)

---

[← Back to Main Documentation](../../README.md)
