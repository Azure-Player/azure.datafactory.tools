
# Lightweight wrapper classes for ADF objects retrieved via REST API.
# Class names follow the AdfPS<SimplifiedType> pattern so that Get-SimplifiedType
# strips the "AdfPS" prefix and returns the correct simplified type (e.g. "Dataset").
# These are used as a fallback when Get-AzDataFactoryV2* cmdlets fail to deserialize
# objects whose types are not yet known to the installed Az.DataFactory module version.

class AdfPSDataset {
    [String] $Name
    AdfPSDataset([String] $name) { $this.Name = $name }
}

class AdfPSDataFlow {
    [String] $Name
    AdfPSDataFlow([String] $name) { $this.Name = $name }
}

class AdfPSPipeline {
    [String] $Name
    AdfPSPipeline([String] $name) { $this.Name = $name }
}

class AdfPSLinkedService {
    [String] $Name
    AdfPSLinkedService([String] $name) { $this.Name = $name }
}

class AdfPSIntegrationRuntime {
    [String] $Name
    AdfPSIntegrationRuntime([String] $name) { $this.Name = $name }
}

class AdfPSTrigger {
    [String] $Name
    [String] $RuntimeState
    AdfPSTrigger([String] $name, [String] $runtimeState) {
        $this.Name = $name
        $this.RuntimeState = $runtimeState
    }
}
