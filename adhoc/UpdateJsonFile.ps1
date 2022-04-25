$file = 'x:\!WORK\GitHub\!SQLPlayer\azure.datafactory.examples\adf-simpledeployment\ArmTemplate\ARMTemplateForFactory.json'

$b = Get-Content -Path $file -Encoding 'utf8' -Raw
$j = $b | ConvertFrom-Json
$j.parameters
$j.resources

$j.parameters.LS_ADLS_properties_typeProperties_url.defaultValue = 'something-new'
$j.resources[0].apiVersion = '2099-01-01'

$j | ConvertTo-Json -Depth 100 | Set-Content -Path "$file.copy.json" -Encoding 'utf8'


$json = $b | ConvertFrom-ArraysToOrderedHashTables
$json
$json.resources[1]
$json.resources["[concat(parameters('factoryName'), '/Input_Binary')]"].apiVersion = '2100-12-31'

# Save
$s = $json | ConvertFrom-OrderedHashTablesToArrays
$s
$s | ConvertTo-Json -Compress:$false -Depth 100 | Set-Content -Path "$file.copy2.json" -Encoding 'utf8'




