$RootFolder = 'D:\azure.datafactory.tools-Export.Test\test\BigFactorySample2'
$DebugPreference = 'Continue'

Publish-AdfV2FromJson -RootFolder $RootFolder -DryRun:$true -stage "globalparam1" -ResourceGroupName 'abc' -DataFactoryName 'xyz'

