function ConvertFrom-ArraysToOrderedHashTables {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)] $Item,
        # This determines the arrays that are converted to OrderedHashTables. Only arrays where the objects have a property
        # with one of the values in this array can be converted, using that property as the key
        [parameter(Mandatory = $false)] [String[]] $ArrayIdProps = @("name", "Name")
    )

    Write-Debug "BEGIN: ConvertFrom-ArraysToOrderedHashTables";

    if ( $Item.GetType().Name -eq "PSCustomObject" ) {

        Write-Debug "Processing PSCustomObject...";
        $cnt = @($Item.PSobject.Properties).Count
        if ($cnt) {
            Write-Debug "Properties: $($Item.PSObject.Properties.Name -join ', ')";
        } else {
            Write-Debug "The object is empty - no further processing";
        }

        # Loop through the properties, changing arrays and processing PSCustomObject's
        foreach ($p in $Item.PSObject.Properties) {

            $prop = $p.Name
            if ($null -eq $Item.$prop) {
                Write-Debug "Skipping property '$prop' as type cannot be determined for null";
                continue;
            }
            Write-Debug "Processing property '$prop' of type '$($Item.$prop.GetType().Name)'";

            # If the current property is a non-empty array
            if ( $Item.$prop.GetType().Name -eq "Object[]" -and $Item.$prop.Count -gt 0) {
            
                $itemCount = $Item.$prop.Count;
                foreach ($idProp in $arrayIdProps) {
                    # If the item in the array is a primitive type, calling PSobject.Properties.Name will throw...
                    $matchedItemCount = $Item.$prop.Where({ (-not $_.GetType().IsPrimitive) -and $_.PSobject.Properties.Name -contains $idProp }, 'Default').Count;

                    if ( $matchedItemCount -eq $itemCount ) {
                        Write-Verbose "Extracting ordered hash table from array using property $idProp as the key";
                        
                        # First convert each item in the array to have ordered hashtables instead of arrays if required
                        for ($i=0; $i -lt $itemCount; $i++ ){
                            $Item.$prop[$i] = ConvertFrom-ArraysToOrderedHashTables -Item $Item.$prop[$i];
                        }
                        # Then convert the actual array to a ordered hashtables
                        $Item.$prop = ArrayToOrderedHash -Array $Item.$prop -KeyProperty $idProp -Verbose:$VerbosePreference;
                        
                        break;
                    }
                }
            }

            elseif ( $Item.$prop.GetType().Name -eq "PSCustomObject" ) {
                Write-Debug "Converting PSCustomObject property using a recursive function call...";

                $Item.$prop = ConvertFrom-ArraysToOrderedHashTables -Item $Item.$prop;
            }
        }

        Write-Debug "END: ConvertFrom-ArraysToOrderedHashTables";
        return $Item;
    }
    elseif ( $Item.GetType().BaseType -eq "Object[]" ) {
        Write-Verbose "Processing Array...";

        $wrapper = [PSCustomObject]@{
            WrappedObject = $Item
        }

        $result = ConvertFrom-ArraysToOrderedHashTables -obj $wrapper;
        Write-Debug "END: ConvertFrom-ArraysToOrderedHashTables";
        return $result.WrappedObject;
    }
    else {
        Write-Debug "Unknown input object type, not supportted";
        Write-Debug "END: ConvertFrom-ArraysToOrderedHashTables";
        return $Item;
    }
}

function ArrayToOrderedHash {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [System.Array] $Array,
        [parameter(Mandatory = $true)] [String] $KeyProperty
    )

    Write-Debug "BEGIN: ArrayToOrderedHash(KeyProperty=$KeyProperty)"

    $hash = [ordered]@{};
    $array | ForEach-Object { $hash[$_.$keyProperty] = $_ };
    return $hash;
}