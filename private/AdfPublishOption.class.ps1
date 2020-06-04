class AdfPublishOption {
    [hashtable] $Includes = @{}
    [hashtable] $Excludes = @{}
    [Boolean] $DeleteNotInSource = $false
    [Boolean] $StopStartTriggers = $true
    [Boolean] $CreateNewInstance = $true
}
