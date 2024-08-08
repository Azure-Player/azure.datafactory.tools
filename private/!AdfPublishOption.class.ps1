enum TriggerStopTypes
{
    AllEnabled
    DeployableOnly
}

enum TriggerStartTypes
{
    BasedOnSourceCode
    KeepPreviousState
}

class AdfPublishOption {
    [hashtable] $Includes = @{}
    [hashtable] $Excludes = @{}
    [Boolean] $DeleteNotInSource = $false
    [Boolean] $StopStartTriggers = $true
    [Boolean] $CreateNewInstance = $true
    [Boolean] $DeployGlobalParams = $true
    [Boolean] $FailsWhenConfigItemNotFound = $true
    [Boolean] $FailsWhenPathNotFound = $true
    [Boolean] $IgnoreLackOfReferencedObject = $false
    [Boolean] $DoNotStopStartExcludedTriggers = $false
    [Boolean] $DoNotDeleteExcludedObjects = $true
    [Boolean] $IncrementalDeployment = $false
    [String] $IncrementalDeploymentStorageUri = ''
    [TriggerStopTypes] $TriggerStopMethod = [TriggerStopTypes]::AllEnabled
    [TriggerStartTypes] $TriggerStartMethod = [TriggerStartTypes]::BasedOnSourceCode
}
