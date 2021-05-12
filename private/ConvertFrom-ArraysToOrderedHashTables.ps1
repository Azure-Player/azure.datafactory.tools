function ConvertFrom-ArraysToOrderedHashTables {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)] $Item,
        # This determines the arrays that are converted to OrderedHashTables. Only arrays where the objects have a property
        # with one of the values in this array can be converted, using that property as the key
        [parameter(Mandatory = $false)] [String[]] $ArrayIdProps = @("name", "Name")
    )

    Write-Verbose "Entering Function: ConvertFrom-ArraysToOrderedHashTables";

    if ( $Item.GetType().Name -eq "PSCustomObject" ) {

        Write-Verbose "Processing PSCustomObject...";
        Write-Verbose "Properties: $($Item.PSObject.Properties.Name)";

        # Loop through the properties, changing arrays and processing PSCustomObject's
        foreach ($prop in $Item.PSObject.Properties.Name) {

            Write-Verbose "Processing property '$prop' of type  $($Item.$prop.GetType().Name)";

            # If the current property is a non-empty array
            if ( $Item.$prop.GetType().Name -eq "Object[]" -and $Item.$prop.Count -gt 0) {
            
                $itemCount = $Item.$prop.Count;
                foreach ($idProp in $arrayIdProps) {
                    $matchedItemCount = $Item.$prop.Where({$_.PSobject.Properties.Name -contains $idProp}, 'Default').Count;

                    if ( $matchedItemCount -eq $itemCount ) {
                    #if ( $Item.$prop[0].$idProp -notcontains $null ) {
                    #if ( $Item.$prop.PSobject.Properties.Name -contains $idProp) {
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
                Write-Verbose "Converting PSCustomObject property using a recursive function call...";

                $Item.$prop = ConvertFrom-ArraysToOrderedHashTables -Item $Item.$prop;
            }
        }

        return $Item;
    }
    elseif ( $Item.GetType().BaseType -eq "Object[]" ) {
        Write-Verbose "Processing Array...";

        $wrapper = [PSCustomObject]@{
            WrappedObject = $Item
        }

        $result = ConvertFrom-ArraysToOrderedHashTables -obj $wrapper;
        return $result.WrappedObject;
    }
    else {
        Write-Verbose "Unknown input object type, not supportted";
        return $Item;
    }
}

function ArrayToOrderedHash {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [System.Array] $Array,
        [parameter(Mandatory = $true)] [String] $KeyProperty
    )

    Write-Verbose "Entering Function: ArrayToOrderedHash";
   
    Write-Verbose "Key property: $keyProperty";

    $hash = [ordered]@{};
    $array | ForEach-Object { $hash[$_.$keyProperty] = $_ };
    return $hash;
}