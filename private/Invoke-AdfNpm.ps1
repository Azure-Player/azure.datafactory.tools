function Get-AdfNpmCommand {
    # On Windows, 'npm' resolves to npm.ps1, which fails on Windows PowerShell 5.1 in some npm versions
    # ($MyInvocation.Statement under strict mode) #462. npm.cmd does the same without PowerShell.
    if ($env:OS -eq 'Windows_NT') { 'npm.cmd' } else { 'npm' }
}

function Invoke-AdfNpm {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [String[]] $Arguments
    )

    $npm = Get-AdfNpmCommand
    Write-Verbose "$npm $($Arguments -join ' ')"
    & $npm @Arguments
    if ($global:LASTEXITCODE -ne 0) {
        throw "Command 'npm $($Arguments -join ' ')' failed with exit code $($global:LASTEXITCODE)."
    }
}
