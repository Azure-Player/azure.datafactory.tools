function ConvertFrom-OrderedHashTablesToArrays {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)] $Item
    )

    Write-Verbose "Entering Function: ConvertFrom-OrderedHashTablesToArrays";

    if ( $Item.GetType().Name -eq "PSCustomObject" ) {

        Write-Verbose "Processing PSCustomObject...";
        Write-Verbose "Properties: $($Item.PSObject.Properties.Name)";

        # Loop through the properties, changing arrays and processing PSCustomObject's
        foreach ($prop in $Item.PSObject.Properties.Name) {
            if ($Item.$prop -eq $null){
                Write-Verbose "Skipping property '$prop' as type cannot be determined for null";
                continue;
            }

            Write-Verbose "Processing property '$prop' of type  $($Item.$prop.GetType().Name)";

            if ( $Item.$prop.GetType().Name -eq "OrderedDictionary" ) {
            
                Write-Verbose "Converting ordered hash table to array";

                # First convert each item in the array to have ordered hashtables instead of arrays if required
                for ($i=0; $i -lt $Item.$prop.Count; $i++ ){
                    $Item.$prop[$i] = ConvertFrom-OrderedHashTablesToArrays -Item $Item.$prop[$i];
                }
                # Then convert the actual array to a ordered hashtables

                # Without the ForEach-Object we get a OrderedDictionaryKeyValueCollection back, which is not too useful. We need an array, or the JSON
                # gets saved using the keys as properties instead of an array. The foreeach unboxes back to an array for us.
                $Item.$prop = $Item.$prop.Values | ForEach-Object { $_ };
            }
            elseif ( $Item.$prop.GetType().Name -eq "PSCustomObject" ) {
                Write-Verbose "Converting PSCustomObject property using a recursive function call...";

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
        Write-Verbose "Unknown input object type, not supportted";
        return $Item;
    }
}
