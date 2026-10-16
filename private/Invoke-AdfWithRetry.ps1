function Invoke-AdfWithRetry {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [scriptblock] $ScriptBlock,
        [parameter(Mandatory = $true)] [string] $Activity,
        [parameter(Mandatory = $false)] [int] $MaxRetries = 3
    )
    Write-Debug "BEGIN: Invoke-AdfWithRetry()"

    # Az cmdlets in $ScriptBlock must be called with -ErrorAction Stop, as they write non-terminating errors
    $retry = 0
    while ($true) {
        try {
            & $ScriptBlock
            break
        }
        catch {
            if ($retry -ge $MaxRetries -or -not (Test-AdfTransientError -ErrorRecord $_)) {
                Write-Debug "END: Invoke-AdfWithRetry() - failed after $($retry + 1) attempt(s)"
                throw
            }
            $retry++
            $delay = [int][Math]::Pow(2, $retry)    # 2, 4, 8... seconds
            Write-Warning "$Activity failed with a temporary error: $($_.Exception.Message) Retry $retry of $MaxRetries in $delay seconds..."
            Start-Sleep -Seconds $delay
        }
    }

    Write-Debug "END: Invoke-AdfWithRetry()"
}
