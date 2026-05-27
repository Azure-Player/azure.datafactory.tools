BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName
    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force

    $script:SrcFolder = "$PSScriptRoot\BigFactorySample2"
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)
    Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.*" -Recurse:$true -Force

    AfterAll {
        Remove-Item -Path $script:TmpFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    # -------------------------------------------------------------------------
    # Issue #472 – Scenario 1: wrong property path in config (ADFT0010)
    #
    # config-c004-wrongpath.csv contains "typeProperties:baseUrl" (colon
    # separator instead of dot), which causes Write-Error "ADFT0010" inside
    # Update-PropertiesForObject.  The error is non-terminating, so the
    # ForEach-Object loop in Update-PropertiesFromFile swallows it and
    # Publish-AdfV2FromJson continues to print "deployed successfully".
    #
    # Expected fix: the error must propagate as a terminating error so the
    # caller observes a failure regardless of $ErrorActionPreference scope.
    # -------------------------------------------------------------------------
    Describe 'Publish-AdfV2FromJson - Error propagation for wrong config path (Issue #472)' -Tag 'Unit' {

        Context 'When stage config has a wrong property path and FailsWhenPathNotFound is true (default)' {

            It 'Should throw when Publish-AdfV2FromJson is called with -DryRun' {
                # BUG REPRODUCTION: currently does NOT throw (Write-Error is swallowed).
                # After fix this test must pass.
                $o = New-AdfPublishOption
                # FailsWhenPathNotFound defaults to $true
                {
                    Publish-AdfV2FromJson `
                        -RootFolder $script:RootFolder `
                        -ResourceGroupName 'rg-test' `
                        -DataFactoryName 'adf-test' `
                        -Stage 'c004-wrongpath' `
                        -Option $o `
                        -DryRun
                } | Should -Throw
            }
        }

        Context 'When stage config has a wrong property path and FailsWhenPathNotFound is false' {

            It 'Should not throw (wrong path is only a warning)' {
                $o = New-AdfPublishOption
                $o.FailsWhenPathNotFound = $false
                {
                    Publish-AdfV2FromJson `
                        -RootFolder $script:RootFolder `
                        -ResourceGroupName 'rg-test' `
                        -DataFactoryName 'adf-test' `
                        -Stage 'c004-wrongpath' `
                        -Option $o `
                        -DryRun
                } | Should -Not -Throw
            }
        }
    }

    # -------------------------------------------------------------------------
    # Issue #472 – Scenario 2: ADF object deployment fails at runtime
    #
    # When Deploy-AdfObjectOnly emits a non-terminating Write-Error (e.g. an
    # Azure Policy block: "RequestDisallowedByPolicy"), the ForEach-Object
    # pipeline in Publish-AdfV2FromJson absorbs the error and the function
    # continues to report "deployed successfully".
    #
    # Expected fix: the deployment loop must propagate errors so the function
    # terminates and the caller sees a failure.
    # -------------------------------------------------------------------------
    Describe 'Publish-AdfV2FromJson - Error propagation for deployment failure (Issue #472)' -Tag 'Unit' {

        Context 'When an ADF object deployment produces a terminating error' {

            BeforeAll {
                Mock Get-AzDataFactoryV2 {
                    [PSCustomObject]@{ Name = 'adf-test'; ResourceGroupName = 'rg-test' }
                }
                # Azure cmdlets (e.g. New-AzResource) throw terminating errors for
                # serious failures like Azure Policy blocks. In PowerShell 5.1 the
                # ForEach-Object pipeline was absorbing these terminating errors and
                # allowing the loop to continue, so the function reported success.
                # The fix replaces ForEach-Object with a foreach statement, which
                # propagates terminating errors correctly in all PS versions.
                Mock Deploy-AdfObjectOnly {
                    throw 'Simulated: RequestDisallowedByPolicy - resource was disallowed by policy'
                }
            }

            It 'Should throw when any object deployment fails' {
                # BUG REPRODUCTION: previously did NOT throw because ForEach-Object
                # absorbed the terminating error in PS 5.1.
                # After fix (foreach loop) this test must pass.
                $o = New-AdfPublishOption
                $o.StopStartTriggers = $false
                $o.DeleteNotInSource = $false
                {
                    Publish-AdfV2FromJson `
                        -RootFolder $script:RootFolder `
                        -ResourceGroupName 'rg-test' `
                        -DataFactoryName 'adf-test' `
                        -Option $o
                } | Should -Throw
            }

            It 'Should throw even when the caller has not set $ErrorActionPreference to Stop' {
                # BUG REPRODUCTION: the module scope isolates $ErrorActionPreference
                # from the caller's script scope, so setting it externally has no effect.
                # The fix must make the function fail independently of the caller's EAP.
                $o = New-AdfPublishOption
                $o.StopStartTriggers = $false
                $o.DeleteNotInSource = $false
                $threw = $false
                # Deliberately NOT using Should -Throw so Pester does not alter EAP
                try {
                    Publish-AdfV2FromJson `
                        -RootFolder $script:RootFolder `
                        -ResourceGroupName 'rg-test' `
                        -DataFactoryName 'adf-test' `
                        -Option $o
                }
                catch {
                    $threw = $true
                }
                $threw | Should -BeTrue -Because 'deployment failures must propagate to the caller'
            }
        }
    }
}
