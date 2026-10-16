BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force

    Describe 'Command ' -Tag 'Unit' {
        It 'Invoke-AdfWithRetry Should exist' {
            { Get-Command -Name Invoke-AdfWithRetry -ErrorAction Stop } | Should -Not -Throw
        }
        It 'Test-AdfTransientError Should exist' {
            { Get-Command -Name Test-AdfTransientError -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Describe 'Test-AdfTransientError #295' -Tag 'Unit' {
        It 'Should return <expected> for "<message>"' -ForEach @(
            @{ message = 'Operation failed because a request timed out.'; expected = $true }
            @{ message = 'A task was canceled.'; expected = $true }
            @{ message = 'The operation has timed out.'; expected = $true }
            @{ message = 'HTTP Status Code: TooManyRequests Error Code: TooManyRequests'; expected = $true }
            @{ message = 'HTTP Status Code: 429'; expected = $true }
            @{ message = 'HTTP Status Code: InternalServerError Error Code: InternalServerError'; expected = $true }
            @{ message = 'HTTP Status Code: ServiceUnavailable'; expected = $true }
            @{ message = 'HTTP Status Code: BadGateway'; expected = $true }
            @{ message = 'HTTP Status Code: GatewayTimeout'; expected = $true }
            @{ message = 'HTTP Status Code: 503'; expected = $true }
            @{ message = 'Conflict: There are concurrent operations on the resource'; expected = $true }
            @{ message = 'HTTP Status Code: BadRequest Error Code: BadRequest Error Message: Invalid pipeline definition'; expected = $false }
            @{ message = 'HTTP Status Code: NotFound Error Code: ResourceNotFound'; expected = $false }
            @{ message = 'RequestDisallowedByPolicy: Resource was disallowed by policy'; expected = $false }
            @{ message = 'AuthorizationFailed: The client does not have authorization'; expected = $false }
            @{ message = 'ADFT0013: Type foo is not supported.'; expected = $false }
        ) {
            $err = [System.Management.Automation.ErrorRecord]::new([System.Exception]::new($message), 'Test', 'NotSpecified', $null)
            Test-AdfTransientError -ErrorRecord $err | Should -Be $expected
        }

        It 'Should return true for TaskCanceledException (HttpClient timeout)' {
            $err = [System.Management.Automation.ErrorRecord]::new([System.Threading.Tasks.TaskCanceledException]::new(), 'Test', 'NotSpecified', $null)
            Test-AdfTransientError -ErrorRecord $err | Should -BeTrue
        }

        It 'Should return true when the timeout is in an inner exception' {
            $inner = [System.TimeoutException]::new('The operation has timed out.')
            $err = [System.Management.Automation.ErrorRecord]::new([System.Exception]::new('Something went wrong', $inner), 'Test', 'NotSpecified', $null)
            Test-AdfTransientError -ErrorRecord $err | Should -BeTrue
        }
    }

    # Az cmdlets report failures as non-terminating errors (they do not throw)
    Describe 'Invoke-AdfWithRetry #295' -Tag 'Unit' {

        BeforeEach {
            $ErrorActionPreference = 'Continue'     # default preference, as in most pipelines
            Mock Start-Sleep {}
            Mock Write-Warning {}
            # Stand-in for an Az cmdlet; mocked per test
            function Invoke-FakeAzCall { [CmdletBinding()] param() }
        }

        It 'Should run once when the call succeeds' {
            Mock Invoke-FakeAzCall { }
            Invoke-AdfWithRetry -Activity 'deploy X' -MaxRetries 3 -ScriptBlock { Invoke-FakeAzCall -ErrorAction Stop }
            Should -Invoke Invoke-FakeAzCall -Times 1 -Exactly
            Should -Invoke Start-Sleep -Times 0 -Exactly
        }

        It 'Should retry a transient error and succeed' {
            $script:attempt = 0
            Mock Invoke-FakeAzCall { $script:attempt++; if ($script:attempt -eq 1) { Write-Error 'Operation failed because a request timed out.' } }
            { Invoke-AdfWithRetry -Activity 'deploy X' -MaxRetries 3 -ScriptBlock { Invoke-FakeAzCall -ErrorAction Stop } } | Should -Not -Throw
            Should -Invoke Invoke-FakeAzCall -Times 2 -Exactly
            Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like '*deploy X*timed out*' }
        }

        It 'Should throw after MaxRetries retries when the error persists' {
            Mock Invoke-FakeAzCall { Write-Error 'Operation failed because a request timed out.' }
            { Invoke-AdfWithRetry -Activity 'deploy X' -MaxRetries 3 -ScriptBlock { Invoke-FakeAzCall -ErrorAction Stop } } | Should -Throw '*timed out*'
            Should -Invoke Invoke-FakeAzCall -Times 4 -Exactly
        }

        It 'Should wait longer before each retry (2, 4, 8 seconds)' {
            Mock Invoke-FakeAzCall { Write-Error 'Operation failed because a request timed out.' }
            { Invoke-AdfWithRetry -Activity 'deploy X' -MaxRetries 3 -ScriptBlock { Invoke-FakeAzCall -ErrorAction Stop } } | Should -Throw
            Should -Invoke Start-Sleep -Times 3 -Exactly
            Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 2 }
            Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 4 }
            Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 8 }
        }

        It 'Should not retry a permanent error' {
            Mock Invoke-FakeAzCall { Write-Error 'HTTP Status Code: BadRequest Error Code: BadRequest Error Message: Invalid pipeline definition' }
            { Invoke-AdfWithRetry -Activity 'deploy X' -MaxRetries 3 -ScriptBlock { Invoke-FakeAzCall -ErrorAction Stop } } | Should -Throw '*Invalid pipeline definition*'
            Should -Invoke Invoke-FakeAzCall -Times 1 -Exactly
            Should -Invoke Start-Sleep -Times 0 -Exactly
        }

        It 'Should not retry when MaxRetries is 0' {
            Mock Invoke-FakeAzCall { Write-Error 'Operation failed because a request timed out.' }
            { Invoke-AdfWithRetry -Activity 'deploy X' -MaxRetries 0 -ScriptBlock { Invoke-FakeAzCall -ErrorAction Stop } } | Should -Throw
            Should -Invoke Invoke-FakeAzCall -Times 1 -Exactly
        }

        It 'Should not retry a terminating error thrown by the module itself' {
            $script:calls = 0
            { Invoke-AdfWithRetry -Activity 'deploy X' -MaxRetries 3 -ScriptBlock { $script:calls++; throw 'ADFT0013: Type foo is not supported.' } } | Should -Throw '*ADFT0013*'
            $script:calls | Should -Be 1
        }
    }

    # Default publish method is 'AzResource' (New-AzResource); 'AzDataFactory' uses Set-AzDataFactoryV2* cmdlets
    Describe 'Deploy-AdfObjectOnly retries transient errors with method <method> #295' -Tag 'Unit' -ForEach @(
        @{ method = 'AzResource';    cmdlet = 'New-AzResource' }
        @{ method = 'AzDataFactory'; cmdlet = 'Set-AzDataFactoryV2Pipeline' }
    ) {

        BeforeAll {
            $script:RootFolder = Join-Path $PSScriptRoot 'BigFactorySample2'
        }

        BeforeEach {
            $ErrorActionPreference = 'Continue'     # default preference, as in most pipelines
            $script:PublishMethod = $method
            Mock Start-Sleep {}
            Mock Write-Warning {}
            $script:adf = Import-AdfFromFolder -FactoryName 'adf-test' -RootFolder $script:RootFolder
            $script:adf.ResourceGroupName = 'rg-test'
            $script:adf.PublishOptions = New-AdfPublishOption
            $script:obj = Get-AdfObjectByName -adf $script:adf -name 'PL_Wait5sec' -type 'pipeline'
        }

        It 'Should deploy the object when a retry succeeds' {
            $script:attempt = 0
            Mock $cmdlet { $script:attempt++; if ($script:attempt -eq 1) { Write-Error 'Operation failed because a request timed out.' } }
            { Deploy-AdfObjectOnly -obj $script:obj } | Should -Not -Throw
            Should -Invoke $cmdlet -Times 2 -Exactly
            $script:obj.Deployed | Should -BeTrue
        }

        It 'Should use MaxRetries from publish options and throw when retries run out' {
            $script:adf.PublishOptions.MaxRetries = 1
            Mock $cmdlet { Write-Error 'Operation failed because a request timed out.' }
            { Deploy-AdfObjectOnly -obj $script:obj } | Should -Throw '*timed out*'
            Should -Invoke $cmdlet -Times 2 -Exactly
            $script:obj.Deployed | Should -BeFalse
        }

        It 'Should throw and not mark as deployed on a permanent error, whatever ErrorActionPreference is' {
            Mock $cmdlet { Write-Error 'HTTP Status Code: BadRequest Error Message: Invalid pipeline definition' }
            { Deploy-AdfObjectOnly -obj $script:obj } | Should -Throw '*Invalid pipeline definition*'
            Should -Invoke $cmdlet -Times 1 -Exactly
            $script:obj.Deployed | Should -BeFalse
        }
    }

    Describe 'New-AdfPublishOption MaxRetries #295' -Tag 'Unit' {
        It 'Should default MaxRetries to 3' {
            (New-AdfPublishOption).MaxRetries | Should -Be 3
        }
    }
}
