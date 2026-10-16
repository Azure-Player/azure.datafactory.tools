function Test-AdfTransientError {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [parameter(Mandatory = $true)] [System.Management.Automation.ErrorRecord] $ErrorRecord
    )

    # Temporary failures worth retrying: timeouts, throttling, server-side errors, concurrent updates
    $transientTypes = @(
        [System.Threading.Tasks.TaskCanceledException],     # HttpClient timeout
        [System.TimeoutException]
    )
    $transientPatterns = @(
        '*timed out*', '*timeout*', '*task was canceled*',
        '*TooManyRequests*', '*Status Code: 429*',
        '*InternalServerError*', '*BadGateway*', '*ServiceUnavailable*', '*GatewayTimeout*',
        '*concurrent operation*'
    )

    $ex = $ErrorRecord.Exception
    while ($null -ne $ex) {
        foreach ($t in $transientTypes) {
            if ($ex -is $t) { return $true }
        }
        foreach ($p in $transientPatterns) {
            if ($ex.Message -like $p) { return $true }
        }
        if ($ex.Message -match 'Status Code: 5\d\d') { return $true }
        $ex = $ex.InnerException
    }
    return $false
}
