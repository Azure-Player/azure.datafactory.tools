BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $script:moduleManifestName = 'azure.datafactory.tools.psd1'
    $script:moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name 'PSScriptAnalyzer'
}

Describe 'azure.datafactory.tools Module'{

    Context 'PSScriptAnalyzer' {

        # Perform PSScriptAnalyzer scan
        $s = @{ 
            Severity = @('Error', 'Warning', 'Information')
        }

        $PSScriptAnalyzerResult = Invoke-ScriptAnalyzer `
            -Path $script:moduleManifestPath `
            -Settings $s `
            -ErrorAction SilentlyContinue `
            -Verbose:$false

        $script:PSScriptAnalyzerErrors = $PSScriptAnalyzerResult | Where-Object {
            $_.Severity -eq 'Error'
        }

        It 'Should have no Error level PowerShell Script Analyzer violations' {
            if ($script:PSScriptAnalyzerErrors -ne $null)
            {
                Write-Warning -Message 'There are Error level PowerShell Script Analyzer violations that must be fixed:'

                foreach ($violation in $PSScriptAnalyzerErrors)
                {
                    Write-Warning -Message "$($violation.Scriptname) (Line $($violation.Line)): $($violation.Message)"
                }

                Write-Warning -Message  'For instructions on how to run PSScriptAnalyzer on your own machine, please go to https://github.com/powershell/psscriptAnalyzer/'

                $PSScriptAnalyzerErrors.Count | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Manifest' {
        $moduleManifestPath = Join-Path -Path $moduleRootPath -ChildPath 'azure.datafactory.tools.psd1'

        It 'Should have a valid manifest' {
            $script:moduleManifest = Test-ModuleManifest -Path $moduleManifestPath
            $script:moduleManifest | Should -Not -BeNullOrEmpty
        }

        It 'Should have less than 10000 characters in the release notes of the module manifest' {
            $script:moduleManifest.ReleaseNotes.Length | Should -BeLessThan 10000
        }

        It 'Should have tags with no spaces' {
            $script:moduleManifest.PrivateData["PSData"]["Tags"] | Where-Object { $_.Split(' ').Length -gt 1 } | Should -Be $null
        }
    }
}
