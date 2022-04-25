$RootFolder = "x:\!WORK\GitAz\sqlplayer\DataServices\ADF-demo\BigFactoryTestWrongRef\"
$VerbosePreference = 'SilentlyContinue'
$VerbosePreference = 'Continue'

Import-Module .\azure.datafactory.tools.psd1 -Force
$a = Import-AdfFromFolder -RootFolder $RootFolder -FactoryName 'abc'
$a.Pipelines[0].Body



function Get-AllProperties {
    [CmdletBinding()]
    param (
        $Item, $path = '$'
    )
    $ArrayIdProps = @("name", "Name")
    if ( $Item.GetType().Name -eq "PSCustomObject" ) {
        foreach ($prop in $Item.PSObject.Properties.Name) {
            Write-Verbose "Processing property '$prop' of type $($Item.$prop.GetType().Name)";
            Write-Host "$path.$prop"
            if ( $Item.$prop.GetType().Name -eq "Object[]" -and $Item.$prop.Count -gt 0) {
                $itemCount = $Item.$prop.Count;
                foreach ($idProp in $arrayIdProps) {
                    $matchedItemCount = $Item.$prop.Where({ (-not $_.GetType().IsPrimitive) -and $_.PSobject.Properties.Name -contains $idProp }, 'Default').Count;

                    if ( $matchedItemCount -eq $itemCount ) {
                        for ($i=0; $i -lt $itemCount; $i++ ){
                            $Item.$prop[$i] = Get-AllProperties -Item $Item.$prop[$i] -path "$path.$prop[$i]"
                        }
                        break;
                    }
                }
            }
            elseif ( $Item.$prop.GetType().Name -eq "PSCustomObject" ) {
                $Item.$prop = Get-AllProperties -Item $Item.$prop  -path "$path.$prop"
            }
        }
        return $Item;
    }
    elseif ( $Item.GetType().BaseType -eq "Object[]" ) {
        $wrapper = [PSCustomObject]@{
            WrappedObject = $Item
        }

        $result = Get-AllProperties -obj $wrapper;
        return $result.WrappedObject;
    }
    else {
        Write-Verbose "Unknown input object type, not supportted";
        return $Item;
    }
}

Get-AllProperties -Item $a.Pipelines[0].Body
Get-AllProperties -Item $a.LinkedServices[0].Body

