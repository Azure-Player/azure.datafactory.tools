$StageConfigFile = 'abc.CSV1'
$ext = [System.IO.Path]::GetExtension($StageConfigFile.ToLower())
$allowedExt = '.csv', '.json'
$allowedExt.Contains($ext)

if (!$StageConfigFile.EndsWith('.csv')) {
    throw ("Invalid config file name '{0}'. File must ends with '.csv'." -f $StageConfigFile)
}
$Stage = $StageConfigFile
$Stage


