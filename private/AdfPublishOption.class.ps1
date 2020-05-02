class AdfPublishOption {
    [hashtable] $Includes = @{}
    [hashtable] $Excludes = @{}
    [Boolean] $DeleteNotInSource = $true
    [Boolean] $StopStartTriggers = $true
}
