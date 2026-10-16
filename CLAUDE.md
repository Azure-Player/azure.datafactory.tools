# CLAUDE.md

## Changelog

- Every functional change must be documented in [changelog.md](changelog.md) **before committing**.
- Each functional change gets **one line at most** in the changelog (one bullet, single line), ending with the issue/PR number, e.g. `#404`.

## Tests (Pester)

- Tests require **Pester 6.0 or newer** (enforced by `test/!RunAllTests.ps1`, which installs it on CI runners).
- Do **not** use `Assert-MockCalled` or `Assert-VerifiableMock` (removed in Pester 6). Use `Should -Invoke <command> -Times N -Exactly` instead; add `-Scope Describe` when the mocked command was called in `BeforeAll`.
- Reason: calling `Assert-MockCalled` makes PowerShell autoload the old built-in Pester 3.4.0 (`C:\Program Files\WindowsPowerShell\Modules`), which takes over `Mock`/`Should` and breaks the whole test run.
- Run tests in a clean process with Pester 6 loaded first, e.g.:

  ```powershell
  pwsh -NoProfile -Command "Import-Module Pester -MinimumVersion 6.0; Import-Module ./azure.datafactory.tools.psd1; Invoke-Pester -Path ./test/Stop-Trigger.Tests.ps1 -Output Detailed"
  ```
