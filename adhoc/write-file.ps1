
$RootFolder = 'x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\~InternalFiles\issue#61\'
$adf = Import-AdfFromFolder -FactoryName 'abc' -RootFolder $RootFolder
$o = $adf.Pipelines[0]
Save-AdfObjectAsFile -obj $o



$RootFolder = "x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.tools\~InternalFiles\Issue#33"
$adf = Import-AdfFromFolder -FactoryName 'abc' -RootFolder $RootFolder
$o = $adf.Pipelines[0]
Save-AdfObjectAsFile -obj $o
$o = $adf.Pipelines[1]
Save-AdfObjectAsFile -obj $o

$o.DependsOn
