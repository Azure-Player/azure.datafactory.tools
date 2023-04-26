function ConvertFrom-OrderedHashTablesToArrays {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)] $Item
    )

    Write-Debug "BEGIN: ConvertFrom-OrderedHashTablesToArrays";

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

            Write-Debug "Processing property '$prop' of type $($Item.$prop.GetType().Name)";

            if ( $Item.$prop.GetType().Name -eq "OrderedDictionary" ) {
            
                Write-Verbose "Converting ordered hash table to array";

                # First convert each item in the array to have arrays instead of ordered hashtables if required
                for ($i=0; $i -lt $Item.$prop.Count; $i++ ){
                    $Item.$prop[$i] = ConvertFrom-OrderedHashTablesToArrays -Item $Item.$prop[$i];
                }
                # Then convert the actual ordered hashtables back to an array

                # Without the ForEach-Object we get a OrderedDictionaryKeyValueCollection back, which is not too useful. We need an array, or the JSON
                # gets saved using the keys as properties instead of an array. The foreeach unboxes back to an array for us.
                $Item.$prop = @($Item.$prop.Values | ForEach-Object { $_ });
            }
            elseif ( $Item.$prop.GetType().Name -eq "PSCustomObject" ) {
                Write-Debug "Converting PSCustomObject property using a recursive function call...";

                $Item.$prop = ConvertFrom-OrderedHashTablesToArrays -Item $Item.$prop;
            }
        }

        return $Item;
    }
    elseif ( $Item.GetType().BaseType -eq "OrderedDictionary" ) {
        Write-Verbose "Processing Array...";

        $wrapper = [PSCustomObject]@{
            WrappedObject = $Item
        }

        $result = ConvertFrom-OrderedHashTablesToArrays -obj $wrapper;
        return $result.WrappedObject;
    }
    else {
        Write-Debug "Unknown input object type, not supportted";
        return $Item;
    }
}
