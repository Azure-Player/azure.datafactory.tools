BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.datafactory.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.datafactory.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force

    # Variables for use in tests
    $script:ResourceGroupName = 'rg-devops-factory'
    $script:Stage = 'UAT'
    $c = Get-AzContext
    $script:guid = $c.Subscription.Id.Substring(0,8)
    $script:DataFactoryOrigName = 'BigFactorySample2'
    $script:DataFactoryName = $script:DataFactoryOrigName + "-$guid"
    $script:SrcFolder = "$PSScriptRoot\$($script:DataFactoryOrigName)"
    $script:Location = "NorthEurope"
    $script:TmpFolder = (New-TemporaryDirectory).FullName
    $script:RootFolder = Join-Path -Path $script:TmpFolder -ChildPath (Split-Path -Path $script:SrcFolder -Leaf)
    $script:CommonParam = @{ 
        ResourceGroupName = $script:ResourceGroupName
        DataFactoryName = $script:DataFactoryName 
    }
    $script:triggerName = 'TR_AlwaysDisabled'
    $script:DoNotStopStartExcludedTriggers = $true
    Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "*.csv" -Recurse:$true -Force 

    BeforeAll {
        $script:TargetAdf = $null

        #Invoke-Expression "explorer.exe '$TmpFolder'"
        $DebugPreference = 'SilentlyContinue'
        Mock Stop-Trigger {
            param ($ResourceGroupName, $DataFactoryName, $Name)
            $o = $script:TargetAdf.GetObjectByFullName("*triggers.$Name")
            $o.RuntimeState = 'Stopped'
            $o.Body.properties.RuntimeState = $o.RuntimeState
        }
        Mock Start-Trigger {
            param ($ResourceGroupName, $DataFactoryName, $Name)
            $o = $script:TargetAdf.GetObjectByFullName("*triggers.$Name")
            $o.RuntimeState = 'Started'
            $o.Body.properties.RuntimeState = $o.RuntimeState
        }
        Mock Stop-TargetTrigger {
            param ($Name, $ResourceGroupName, $DataFactoryName)
            $o = $script:TargetAdf.GetObjectByFullName("*triggers.$Name")
            $o.RuntimeState = 'Stopped'
            $o.Body.properties.RuntimeState = $o.RuntimeState
        }
        Mock Start-TargetTrigger {
            param ($Name, $ResourceGroupName, $DataFactoryName)
            $o = $script:TargetAdf.GetObjectByFullName("*triggers.$Name")
            $o.RuntimeState = 'Started'
            $o.Body.properties.RuntimeState = $o.RuntimeState
        }
        Mock Set-AzDataFactoryV2 {
            param ($ResourceGroupName, $DataFactoryName, $Location)
            $script:TargetAdf = CreateTargetAdf
            $script:TargetAdf.Name = $DataFactoryName
            $script:TargetAdf.ResourceGroupName = $ResourceGroupName
            $script:TargetAdf.Location = $Location
            return $script:TargetAdf
        }
        Mock Get-AzDataFactoryV2 {
            param ($ResourceGroupName, $Name)
            return $script:TargetAdf
        }
        Mock Get-AdfFromService {
            param ($FactoryName, $ResourceGroupName)
            return $script:TargetAdf
        }
        Mock New-AzResource {
            param ($ResourceType, $ResourceGroupName, $ResourceName, $ApiVersion, $Properties, $IsFullObject)
            $newRes = New-Object -TypeName "AdfObject"
            $newRes.Name = ($ResourceName -split '/')[1]
            $newRes.Type = $ResourceType
            $newRes.Body = $Properties
            if ($ResourceType -like '*triggers' -and $Properties) {
                $newRes.RuntimeState = $Properties.properties.RuntimeState
            }
            $script:TargetAdf.DeployObject($newRes)
        }
        Mock -CommandName 'Get-AzDataFactoryV2Trigger' -MockWith {
            param ($ResourceGroupName, $DataFactoryName, $Name)
            if (!$Name) { $Name = '*' }
            $r = $script:TargetAdf.GetObjectsByFullName("*triggers.$Name")
            return $r
        }
        Mock -CommandName 'Get-AzDataFactoryV2Trigger' -MockWith {
            param ([System.String] $ResourceGroupName, [System.String] $DataFactoryName)
            $r = $script:TargetAdf.GetObjectsByFullName("*triggers.*")
            return $r
        }
        Mock -CommandName 'Set-AzDataFactoryV2Trigger' -MockWith {
            param ($ResourceGroupName, $DataFactoryName, $TriggerName, $DefinitionFile)
            $body = (Get-Content -Path $DefinitionFile -Encoding "UTF8" | ConvertFrom-Json)
            #$json = $body | ConvertFrom-Json
            $newRes = New-Object -TypeName "AdfObject"
            $newRes.Name = $TriggerName
            $newRes.Type = 'trigger'
            $newRes.Body = $body
            $newRes.RuntimeState = $body.properties.RuntimeState
            $script:TargetAdf.DeployObject($newRes)
        }
        Mock Get-SortedTriggers {
            param ($DataFactoryName, $ResourceGroupName)
            return $script:TargetAdf.GetObjectsByFullName("*triggers.*")
        }
        Mock Remove-TargetTrigger {
            param ($Name, $DataFactoryName, $ResourceGroupName)
            if ($script:TargetAdf) {
                $script:TargetAdf.RemoveObject("*triggers.$Name")
            }
        }
        Mock Remove-AzDataFactoryV2Trigger {
            param ($Name, $DataFactoryName, $ResourceGroupName)
            if ($script:TargetAdf) {
                $script:TargetAdf.RemoveObject("*triggers.$Name")
            }
        }
    }

    Describe 'Publish trigger exists on both sides' -Tag 'Integration', 'triggers' {

        $cases = 
        @{ Case = 'B01' ; DesiredState = 'Enabled' ; CurrentState = 'Enabled' ; Mode = 'Included' ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'B02' ; DesiredState = 'Enabled' ; CurrentState = 'Disabled'; Mode = 'Included' ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'B03' ; DesiredState = 'Disabled'; CurrentState = 'Enabled' ; Mode = 'Included' ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Disabled'},
        @{ Case = 'B04' ; DesiredState = 'Enabled' ; CurrentState = 'Enabled' ; Mode = 'Included' ; StopStartTriggers = $false; ShouldThrow = $true ; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'B05' ; DesiredState = 'Enabled' ; CurrentState = 'Disabled'; Mode = 'Included' ; StopStartTriggers = $false; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Disabled'},
        @{ Case = 'B06' ; DesiredState = 'Disabled'; CurrentState = 'Enabled' ; Mode = 'Included' ; StopStartTriggers = $false; ShouldThrow = $true ; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'B07' ; DesiredState = 'Enabled' ; CurrentState = 'Enabled' ; Mode = 'Excluded' ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'B08' ; DesiredState = 'Enabled' ; CurrentState = 'Disabled'; Mode = 'Excluded' ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Disabled'},
        @{ Case = 'B09' ; DesiredState = 'Disabled'; CurrentState = 'Enabled' ; Mode = 'Excluded' ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'B10' ; DesiredState = 'Enabled' ; CurrentState = 'Enabled' ; Mode = 'Excluded' ; StopStartTriggers = $false; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'B11' ; DesiredState = 'Enabled' ; CurrentState = 'Disabled'; Mode = 'Excluded' ; StopStartTriggers = $false; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Disabled'},
        @{ Case = 'B12' ; DesiredState = 'Disabled'; CurrentState = 'Enabled' ; Mode = 'Excluded' ; StopStartTriggers = $false; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Enabled' }

        It 'has 1 trigger on target' {
            # Prep target trigger
            Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "$triggerName.json" -Recurse:$true -Force 
            Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "PL_Wait5sec.json" -Recurse:$true -Force 
            Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                -ResourceGroupName "$ResourceGroupName" `
                -DataFactoryName "$DataFactoryName" `
                -Location "$Location"
            $tr = Get-AzDataFactoryV2Trigger @script:CommonParam
            $arr = $tr | ToArray
            $script:TriggersInServiceCount = $arr.Count
            $script:TriggersInServiceCount | Should -Be 1
        }

        It 'Case #<Case>(A) when Current State = <CurrentState>, Desired State=<DesiredState>, trigger <Mode>, StopStart=<StopStartTriggers> and TriggerStopMethod=AllEnabled should find trigger <StateAfter>' -TestCases $cases {
            param
            (
                [ValidateSet('Enabled','Disabled')]
                [string] $DesiredState,
                [ValidateSet('Enabled','Disabled')]
                [string] $CurrentState,
                [ValidateSet('Included','Excluded')]
                [string] $Mode,
                [boolean] $StopStartTriggers,
                [int] $TrExistsAfter,
                [switch] $ShouldThrow,
                [string] $StateAfter
            )

            $script:triggerName = 'TR_AlwaysDisabled'
            $script:tsm = 'AllEnabled'
            $script:stage = "trigger-$DesiredState"
            $script:DeleteNIS = $false
            $filePath = $PSScriptRoot | Join-Path -ChildPath 'Triggers_template.ps1'
            . $filePath
        }

        It 'Case #<Case>(B) when Current State = <CurrentState>, Desired State=<DesiredState>, trigger <Mode>, StopStart=<StopStartTriggers> and TriggerStopMethod=DeployableOnly should find trigger <StateAfter>' -TestCases $cases {
            param
            (
                [ValidateSet('Enabled','Disabled')]
                [string] $DesiredState,
                [ValidateSet('Enabled','Disabled')]
                [string] $CurrentState,
                [ValidateSet('Included','Excluded')]
                [string] $Mode,
                [boolean] $StopStartTriggers,
                [int] $TrExistsAfter,
                [switch] $ShouldThrow,
                [string] $StateAfter
            )

            $script:triggerName = 'TR_AlwaysDisabled'
            $script:tsm = 'DeployableOnly'
            $script:stage = "trigger-$DesiredState"
            $script:DeleteNIS = $false
            $filePath = $PSScriptRoot | Join-Path -ChildPath 'Triggers_template.ps1'
            . $filePath
        }

    }    


    Describe 'Publish trigger exists in the source only' -Tag 'Integration', 'triggers' {

        BeforeEach {
            $script:TargetAdf = $null
        }

        $cases = 
        @{ Case = 'S01' ; DesiredState = 'Enabled' ; Mode = 'Included' ; StopStartTriggers = $true ; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'S02' ; DesiredState = 'Disabled'; Mode = 'Included' ; StopStartTriggers = $true ; TrExistsAfter = 1 ; StateAfter = 'Disabled' },
        @{ Case = 'S03' ; DesiredState = 'Enabled' ; Mode = 'Excluded' ; StopStartTriggers = $true ; TrExistsAfter = 0 ; StateAfter = '' },
        @{ Case = 'S04' ; DesiredState = 'Disabled'; Mode = 'Excluded' ; StopStartTriggers = $true ; TrExistsAfter = 0 ; StateAfter = '' }

        It 'Case #<Case> when Desired State=<DesiredState>, trigger <Mode> and StopStart=<StopStartTriggers> should not failed' -TestCases $cases {
            param
            (
                [ValidateSet('Enabled','Disabled')]
                [string] $DesiredState,
                [ValidateSet('Included','Excluded')]
                [string] $Mode,
                [boolean] $StopStartTriggers,
                [int] $TrExistsAfter,
                [string] $StateAfter
            )

            Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "$triggerName.json" -Recurse:$true -Force 
            Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "PL_Wait5sec.json" -Recurse:$true -Force 
            $script:opt = New-AdfPublishOption
            if ($Mode -eq 'Included') { $script:opt.Includes.Add("*.*", "") }
            if ($Mode -eq 'Excluded') { $script:opt.Excludes.Add("*.*", "") }
            $script:opt.StopStartTriggers = $StopStartTriggers
            $opt.DoNotStopStartExcludedTriggers = $DoNotStopStartExcludedTriggers

            { Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                -ResourceGroupName "$ResourceGroupName" `
                -DataFactoryName "$DataFactoryName" `
                -Location "$Location" -Option $script:opt -Stage "trigger-$DesiredState"
            } | Should -Not -Throw

            $script:TriggersOnDiskCount = (Get-ChildItem -Path "$RootFolder\trigger" -Filter "$triggerName.json" -Recurse:$true | Measure-Object).Count
            $tr = Get-AzDataFactoryV2Trigger @script:CommonParam
            $arr = $tr | ToArray
            $script:TriggersInServiceCount = $arr.Count
            $script:TriggersInServiceCount | Should -Be $TrExistsAfter
            if ($TrExistsAfter -eq 1)
            {
                $arr[0].RuntimeState | Should -Be (ConvertTo-RuntimeState $StateAfter)
            }
        }
    }


    Describe 'Publish trigger exists in target only' -Tag 'Integration', 'triggers' {

        BeforeEach {
            $script:TargetAdf = $null
        }

        It 'has 1 trigger on target' {
            # Prep target trigger
            Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "$triggerName.json" -Recurse:$true -Force 
            Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "PL_Wait5sec.json" -Recurse:$true -Force 
            Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                -ResourceGroupName "$ResourceGroupName" `
                -DataFactoryName "$DataFactoryName" `
                -Location "$Location"
            #$tr = Get-AzDataFactoryV2Trigger @script:CommonParam
            $tr = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -TriggerName $triggerName #-ErrorAction:SilentlyContinue

            $arr = $tr | ToArray
            $script:TriggersInServiceCount = $arr.Count
            $script:TriggersInServiceCount | Should -Be 1
        }

        It 'has no triggers in source' {
            Remove-Item -Path "$RootFolder\trigger\*.*"
            $TriggersOnDiskCount = (Get-ChildItem -Path "$RootFolder\trigger" -Filter "$triggerName.json" -Recurse:$true | Measure-Object).Count
            $TriggersOnDiskCount | Should -Be 0
        }

        $cases = 
        @{ Case = 'T01' ; CurrentState = 'Enabled' ; Mode = 'Included' ; DeleteNIS = $false ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Disabled' },
        @{ Case = 'T02' ; CurrentState = 'Disabled'; Mode = 'Included' ; DeleteNIS = $false ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Disabled' },
        @{ Case = 'T03' ; CurrentState = 'Enabled' ; Mode = 'Excluded' ; DeleteNIS = $false ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'T04' ; CurrentState = 'Disabled'; Mode = 'Excluded' ; DeleteNIS = $false ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Disabled' },
        @{ Case = 'T05' ; CurrentState = 'Enabled' ; Mode = 'Included' ; DeleteNIS = $true  ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 0 ; StateAfter = '' },
        @{ Case = 'T06' ; CurrentState = 'Disabled'; Mode = 'Included' ; DeleteNIS = $true  ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 0 ; StateAfter = '' },
        @{ Case = 'T07' ; CurrentState = 'Enabled' ; Mode = 'Excluded' ; DeleteNIS = $true  ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'T08' ; CurrentState = 'Disabled'; Mode = 'Excluded' ; DeleteNIS = $true  ; StopStartTriggers = $true ; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Disabled' },
        @{ Case = 'T09' ; CurrentState = 'Enabled' ; Mode = 'Included' ; DeleteNIS = $false ; StopStartTriggers = $false; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'T10' ; CurrentState = 'Disabled'; Mode = 'Included' ; DeleteNIS = $false ; StopStartTriggers = $false; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Disabled' },
        @{ Case = 'T11' ; CurrentState = 'Enabled' ; Mode = 'Excluded' ; DeleteNIS = $false ; StopStartTriggers = $false; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'T12' ; CurrentState = 'Disabled'; Mode = 'Excluded' ; DeleteNIS = $false ; StopStartTriggers = $false; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Disabled' },
        @{ Case = 'T13' ; CurrentState = 'Enabled' ; Mode = 'Included' ; DeleteNIS = $true  ; StopStartTriggers = $false; ShouldThrow = $true ; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'T14' ; CurrentState = 'Disabled'; Mode = 'Included' ; DeleteNIS = $true  ; StopStartTriggers = $false; ShouldThrow = $false; TrExistsAfter = 0 ; StateAfter = '' },
        @{ Case = 'T15' ; CurrentState = 'Enabled' ; Mode = 'Excluded' ; DeleteNIS = $true  ; StopStartTriggers = $false; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Enabled' },
        @{ Case = 'T16' ; CurrentState = 'Disabled'; Mode = 'Excluded' ; DeleteNIS = $true  ; StopStartTriggers = $false; ShouldThrow = $false; TrExistsAfter = 1 ; StateAfter = 'Disabled' }

        It 'Case #<Case> when Current State = <CurrentState>, DeleteNotInSource=<DeleteNIS>, trigger <Mode> and StopStart=<StopStartTriggers> should find trigger <StateAfter>' -TestCases $cases {
            param
            (
                [ValidateSet('Enabled','Disabled')]
                [string] $CurrentState,
                [ValidateSet('Included','Excluded')]
                [string] $Mode,
                [boolean] $DeleteNIS,
                [boolean] $StopStartTriggers,
                [int] $TrExistsAfter,
                [switch]$ShouldThrow,
                [string] $StateAfter
            )

            # Prep target ADF with trigger
            $script:DataFactoryName = $script:DataFactoryOrigName + "-$case"
            Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "$triggerName.json" -Recurse:$true -Force -Verbose:$false
            Copy-Item -Path "$SrcFolder" -Destination "$TmpFolder" -Filter "PL_Wait5sec.json" -Recurse:$true -Force  -Verbose:$false
            Publish-AdfV2FromJson -RootFolder "$RootFolder" `
                -ResourceGroupName "$ResourceGroupName" `
                -DataFactoryName "$DataFactoryName" `
                -Location "$Location"
            Remove-Item -Path "$RootFolder\trigger\*.*" -Verbose:$false
            
            $script:triggerName = 'TR_AlwaysDisabled'
            $script:tsm = 'AllEnabled'
            $script:stage = ''
            $filePath = $PSScriptRoot | Join-Path -ChildPath 'Triggers_template.ps1'
            . $filePath

        }

    }    


}
