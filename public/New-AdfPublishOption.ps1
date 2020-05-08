<#
.SYNOPSIS
Creates an instance of objects with options for publishing ADF.

.DESCRIPTION
Creates an instance of objects with options for publishing ADF.
Use it if you want specify particular behaviour during publish operation.

.EXAMPLE
$opt = New-AdfPublishOption
$opt.Includes.Add("pipeline.Copy*", "")
$opt.DeleteNotInSource = $false
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Stage "UAT" -Option $opt

.EXAMPLE
$opt = New-AdfPublishOption
$opt.DeleteNotInSource = $false
$opt.StopStartTriggers = $false
Publish-AdfV2FromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -DataFactoryName "$DataFactoryName" -Location "$Location" -Stage "UAT" -Option $opt

.LINK
Online version: https://github.com/SQLPlayer/azure.datafactory.tools/
#>
function New-AdfPublishOption {
    [CmdletBinding()]
    param (    )

    return (New-Object -TypeName AdfPublishOption)

}