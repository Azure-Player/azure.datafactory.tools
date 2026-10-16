# CLAUDE.md

## Branches and releases

- Feature/fix branches start from `develop`, and their PRs go into `develop`. Never merge a feature branch straight into `master`: `develop` then misses the change (this happened with #502).
- Release: a PR from `develop` into `master`. After the release, move `develop` to `master` (a fast-forward, no force-push needed).
- The version is set **at release**: feature PRs add changelog lines under `## [Unreleased]`; the release PR replaces it with `## [x.y.z] - yyyy-mm-dd` and bumps `ModuleVersion` in `azure.datafactory.tools.psd1` to the same version.

## Issues and PRs

- Before coding, post the root cause and the planned approach as a comment on the GitHub issue.
- When an issue contains independent problems, create a sub-issue for each and link them to the parent.
- PR descriptions say `Closes #n` for the issues they resolve.

## Changelog

- Every functional change must be documented in [changelog.md](changelog.md) **before committing**.
- Each functional change gets **one line at most** in the changelog (one bullet, single line), ending with the issue/PR number, e.g. `#404`.
- A behaviour change (e.g. an error now stops the publish) counts as a functional change, even inside a test-only or refactoring PR.

## Error handling (Az cmdlets)

- Az cmdlets (`Set-AzDataFactoryV2*`, `Start-/Stop-AzDataFactoryV2Trigger`, `New-AzResource`, ...) report failures as **non-terminating** errors. `try/catch` does not see them unless the call has `-ErrorAction Stop`. Always add `-ErrorAction Stop` to an Az call inside `try`, and never rely on the caller's `$ErrorActionPreference`.
- Retry only temporary errors (time-outs, HTTP 429, HTTP 5xx, concurrent operations) with `Invoke-AdfWithRetry` / `Test-AdfTransientError`; permanent errors fail at once.
- Validation belongs in `Test-AdfCode` (build/test time), where the source tells us exactly what is wrong. At deployment time we can only pass on the Azure API message.
- A failed object deployment stops the publish. A trigger that fails to start or stop is only a warning, and the deployment carries on.

## PowerShell strict mode

- The module runs with `Set-StrictMode -Version Latest`: reading a property that does not exist throws, and so does `.Count` on `$null`.
- Check optional JSON properties first, e.g. `'pipelines' -in $obj.PSObject.Properties.Name`.
- Assigning an `if`/`switch` statement to a variable unrolls arrays (an empty array becomes `$null`). Wrap it: `$x = @(if (...) { ... })`.

## Tests (Pester)

- Tests require **Pester 6.0 or newer** (enforced by `test/!RunAllTests.ps1`, which installs it on CI runners).
- Do **not** use `Assert-MockCalled` or `Assert-VerifiableMock` (removed in Pester 6). Use `Should -Invoke <command> -Times N -Exactly` instead; add `-Scope Describe` when the mocked command was called in `BeforeAll`.
- Reason: calling `Assert-MockCalled` makes PowerShell autoload the old built-in Pester 3.4.0 (`C:\Program Files\WindowsPowerShell\Modules`), which takes over `Mock`/`Should` and breaks the whole test run.
- **Bug fixes start with a test** that reproduces the bug; run it and see it fail before writing the fix.
- Mocks of Az cmdlets must `Write-Error` (non-terminating, like the real cmdlets), not `throw`. Mocks that `throw` hid the bugs in #508 and #295.
- CI runs with `$ErrorActionPreference = 'Stop'`. Run new or changed tests under both `Stop` and `Continue`; set `$ErrorActionPreference = 'Continue'` in `BeforeEach` to test the default behaviour.
- `Publish-AdfV2FromJson` deploys with `-Method AzResource` (`New-AzResource`) by default; deployment tests should cover both `AzResource` and `AzDataFactory` (`Set-AzDataFactoryV2*`).
- Run tests in a clean process with Pester 6 loaded first, e.g.:

  ```powershell
  pwsh -NoProfile -Command "Import-Module Pester -MinimumVersion 6.0; Import-Module ./azure.datafactory.tools.psd1; Invoke-Pester -Path ./test/Stop-Trigger.Tests.ps1 -Output Detailed"
  ```
