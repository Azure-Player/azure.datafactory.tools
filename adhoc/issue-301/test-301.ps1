
$datevalue = [DateTime]"2020-06-01T23:22:11.555Z"
$datevalue
$datevalue = [DateTime]"2020-06-01T23:22:11.555"
$datevalue
$datevalue = [DateTime]"2020-06-01T23:22:11"
$datevalue

[datetime]::parseExact("2020-06-01T23:22:11.555Z", 'yyyy-MM-ddTHH:mm:ss.fffZ', $null)
[datetime]::parse("2020-06-01T23:22:11.555Z")
[datetime]::parse("2020-06-01T23:22:11.555", $null, 'RoundtripKind')

$value = "2020-06-01T23:22:11.555Z"
$datevalue = [DateTime]::parse($value, $null, 'RoundtripKind')
Get-Date $datevalue -Format "yyyy-MM-ddTHH:mm:ss.fffZ"

$value = "2020-12-31T23:22:11.555Z"
$datevalue = [DateTime]::parse($value, $null, 'RoundtripKind')
Get-Date $datevalue -Format "yyyy-MM-ddTHH:mm:ss.fffZ"


## https://github.com/PowerShell/PowerShell/issues/13592

Write-Host("PowerShell version: " + $PSVersionTable.PSVersion.ToString())
$date = "2020-06-01T09:44:13.769Z"
Write-Host ("Original string: " + $date)
Write-Host("Cast to Datetime: " + [datetime] $date)
Write-Host("Month: " + ([datetime] $date).Month)
$json = ('[{"start":"' + $date + '"}]') 
Write-Host("JSON data: " + $json)
$data = $json |  ConvertFrom-Json
Write-Host($data[0].start.GetType().Name + " resulting from ConvertFrom-JSON: " + $data[0].start)
$date = $data[0].start
$date


##-------

Write-Host("PowerShell version: " + $PSVersionTable.PSVersion.ToString())
$date = "2020-12-31T09:44:13.769Z"
Write-Host ("Original string: " + $date)
Write-Host("Cast to Datetime: " + [datetime] $date)
$json = ('[{"start":"' + $date + '"}]') 
Write-Host("JSON data: " + $json)
$data = ($json |  ConvertFrom-Json)
Write-Host($data[0].start.GetType().Name + " resulting from ConvertFrom-JSON: " + $data[0].start)
Write-Host($data[0].start.GetType().Name + " resulting from ConvertFrom-JSON -- '.Kind' property: " + $data[0].start.Kind)
Write-Host($data[0].start.GetType().Name + " resulting from ConvertFrom-JSON, with .ToLocalTime() applied: " + $data[0].start.ToLocalTime())

$date = [datetime] $date
$date
$date.GetType()
$date.Kind
$date.ToLocalTime()
$date.ToUniversalTime()

