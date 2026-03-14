# Documentation Index

Welcome to the **azure.datafactory.tools** documentation. This guide covers everything from installation to advanced deployment scenarios.

## 🚀 Getting Started

New to the module? Start here:

- **[Getting Started](GETTING_STARTED.md)** - Installation, requirements, and your first deployment

## 📖 Core Guides

### [Publishing Workflow](GUIDE/PUBLISHING.md)
Learn how the deployment process works step-by-step, from loading files to restarting triggers.

### [Publish Options - Filtering & Controls](GUIDE/PUBLISH_OPTIONS.md)
Control which objects get deployed using includes/excludes patterns and templates.

### [Configuration & Environment Replacement](GUIDE/CONFIGURATION.md)
Replace environment-specific values (connection strings, URLs, etc.) using CSV or JSON config files.

### [Selective Deployment, Triggers & Logic](GUIDE/SELECTIVE_DEPLOYMENT.md)
Advanced deployment scenarios with complex trigger management and safety considerations.

### [Incremental Deployment](GUIDE/INCREMENTAL_DEPLOYMENT.md)
Speed up CI/CD by deploying only changed objects (60-90% faster).

## 🔧 Features

### [Build and Test ADF Code](FEATURES/BUILD_AND_TEST.md)
Validate ADF code before deployment with `Test-AdfCode`.

### [Generate Dependencies Diagram](FEATURES/DEPENDENCIES_DIAGRAM.md)
Auto-generate Mermaid diagrams showing object relationships and dependencies.

### [Test Linked Service Connections](FEATURES/LINKED_SERVICE_TESTING.md)
Automate testing of linked service connectivity with `Test-AdfLinkedServiceConnection`.

### [Export and Publish Using ARM Templates](FEATURES/ARM_TEMPLATE.md)
Convert ADF code to ARM templates for infrastructure-as-code deployments.

## 💻 Advanced Topics

### [Azure DevOps Integration](ADVANCED/DEVOPS_INTEGRATION.md)
Build multi-stage CI/CD pipelines with approval gates and environment promotions.

### [Cmdlet Reference](ADVANCED/CMDLET_REFERENCE.md)
Complete reference of all PowerShell cmdlets and configuration options.

---

## Quick Navigation by Task

### "I want to..."

| Goal | Documentation |
|------|---------------|
| Deploy ADF for the first time | [Getting Started](GETTING_STARTED.md) → [Publishing Workflow](GUIDE/PUBLISHING.md) |
| Deploy only specific objects | [Publish Options](GUIDE/PUBLISH_OPTIONS.md) |
| Use different values per environment | [Configuration & Stages](GUIDE/CONFIGURATION.md) |
| Speed up deployments | [Incremental Deployment](GUIDE/INCREMENTAL_DEPLOYMENT.md) |
| Validate code before deploy | [Build & Test](FEATURES/BUILD_AND_TEST.md) |
| Understand what will deploy | [Generate Dependencies](FEATURES/DEPENDENCIES_DIAGRAM.md) |
| Test connections automatically | [Test Linked Services](FEATURES/LINKED_SERVICE_TESTING.md) |
| Automate in Azure DevOps | [DevOps Integration](ADVANCED/DEVOPS_INTEGRATION.md) |
| View all functions/options | [Cmdlet Reference](ADVANCED/CMDLET_REFERENCE.md) |

---

## Common Workflows

### Scenario 1: Deploy to Production

```powershell
Import-Module azure.datafactory.tools

# 1. Validate code
$errors = Test-AdfCode -RootFolder 'c:\MyADF'
if ($errors -gt 0) { exit 1 }

# 2. Deploy with prod configuration
Publish-AdfV2FromJson `
    -RootFolder 'c:\MyADF' `
    -ResourceGroupName 'rg-prod' `
    -DataFactoryName 'adf-prod' `
    -Location 'NorthEurope' `
    -Stage 'PROD'
```

See: [Configuration & Stages](GUIDE/CONFIGURATION.md)

### Scenario 2: Deploy Only Pipelines

```powershell
$opt = New-AdfPublishOption
$opt.Includes.Add('pipeline.*', '')  # Include only pipelines
$opt.DeleteNotInSource = $false

Publish-AdfV2FromJson -Option $opt ...
```

See: [Publish Options](GUIDE/PUBLISH_OPTIONS.md)

### Scenario 3: Speed Up With Incremental Deployment

```powershell
$opt = New-AdfPublishOption
$opt.IncrementalDeployment = $true
$opt.IncrementalDeploymentStorageUri = 'https://storage.../path'

Publish-AdfV2FromJson -Option $opt ...
```

See: [Incremental Deployment](GUIDE/INCREMENTAL_DEPLOYMENT.md)

### Scenario 4: CI/CD Pipeline

```yaml
# See: Azure DevOps Integration
stages:
  - stage: Validate
  - stage: DeployDev
  - stage: DeployProd
    environment: Production  # Approval gate
```

See: [Azure DevOps Integration](ADVANCED/DEVOPS_INTEGRATION.md)

---

## Folder Structure

```
docs/
  README.md                               # This file
  GETTING_STARTED.md                     # Installation & quick start
  GUIDE/
    PUBLISHING.md                         # Core workflow
    PUBLISH_OPTIONS.md                    # Filtering & includes/excludes
    CONFIGURATION.md                      # Environment values, stages, config files
    SELECTIVE_DEPLOYMENT.md               # Advanced trigger logic, safety
    INCREMENTAL_DEPLOYMENT.md             # Change detection, speed optimization
  FEATURES/
    BUILD_AND_TEST.md                     # Code validation
    DEPENDENCIES_DIAGRAM.md               # Mermaid diagram generation
    LINKED_SERVICE_TESTING.md             # Connection testing
    ARM_TEMPLATE.md                       # ARM template export/deploy
  ADVANCED/
    DEVOPS_INTEGRATION.md                 # CI/CD pipelines, Azure DevOps
    API_REFERENCE.md                      # Complete cmdlet reference
```

---

## Support & Resources

- **Module Source:** [PowerShell Gallery](https://www.powershellgallery.com/packages/azure.datafactory.tools)
- **GitHub Issues:** [Report a bug or request feature](https://github.com/SQLPlayer/azure.datafactory.tools/issues)
- **Blog:** [azureplayer.net](https://azureplayer.net)

---

## Key Concepts

### Objects & Types
ADF contains different object types: pipelines, datasets, linked services, triggers, data flows, integration runtimes, etc.

### Deployment Order
The module automatically determines the correct deployment order based on object dependencies.

### Configuration Files
Use CSV or JSON files to replace environment-specific values without modifying source code.

### Publish Options
Control deployment behavior: what gets deployed, whether triggers are managed, whether objects are deleted.

### Incremental Mode
Speeds up deployments by tracking object hashes and deploying only changes.

---

## Need Help?

- **Getting started?** → [Getting Started](GETTING_STARTED.md)
- **How does deployment work?** → [Publishing Workflow](GUIDE/PUBLISHING.md)
- **Want to filter objects?** → [Publish Options](GUIDE/PUBLISH_OPTIONS.md)
- **Environment-specific values?** → [Configuration](GUIDE/CONFIGURATION.md)
- **Advanced scenarios?** → [Selective Deployment](GUIDE/SELECTIVE_DEPLOYMENT.md)
- **API details?** → [Cmdlet Reference](ADVANCED/CMDLET_REFERENCE.md)

---

**Last Updated:** March 2026  
**Version:** 1.0 (Restructured Documentation)
