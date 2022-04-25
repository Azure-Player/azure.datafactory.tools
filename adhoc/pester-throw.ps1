Describe "Get-Computer1" {
    # function is here only to make the example work
    function Get-Computer1 { throw [NotImplementedException]'' }

    It 'throws argument exception when given $null' {
        { Get-Computer1 `$null } |
            Should -Throw -ExceptionType ([ArgumentException])
    }
}

Describe "Get-Computer2" {
    # function is here only to make the example work
    function Get-Computer2 {
        throw [ArgumentNullException]'Value was null.' }

    It 'throws argument exception when given $null' {
        { Get-Computer2 `$null } |
            Should -Throw `
                -ExceptionType ([ArgumentException]) `
                -ErrorId 'SpecificErrorId'
    }
}


# cls; Invoke-Pester -Script ".\debug\pester-throw.ps1"
