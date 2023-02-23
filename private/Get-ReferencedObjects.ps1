function Find-RefObject($node, $list) {
    #Write-Verbose "Type = $($node.GetType().Name)"

    $script:ind++
    if ($null -eq $node) { $script:ind--; return }
    if ($node.GetType().Name -notin ('Object[]','PSCustomObject')) { $script:ind--; return }
    if ($null -ne $node.PSobject -and @($node.PSobject.Properties).Count -gt 0 `
        -and $node.PSobject.Properties.Name -contains 'referenceName' `
        -and $node.PSobject.Properties.Name -contains 'type') 
    {
        [string] $type = $node.type
        if ($type.EndsWith('Reference')) {
            $type = $type.Substring(0, $type.Length-9)
            $refNameType = $node.referenceName.GetType().Name
            #Write-Verbose "$refNameType"
            if ($refNameType -eq 'string') {
                $refFullName = "$type.$($node.referenceName)"
                #Write-Verbose "$refFullName"
                $list.Add($refFullName) | Out-Null
            } else {
                $refFullName = "$type.Expression" 
                #Write-Verbose "$refFullName"
                $list.Add($refFullName) | Out-Null
            }
        }
    }

    if ($node.GetType().Name -eq 'Object[]')
    {
        foreach ($item in $node) {
            Find-RefObject -node $item -list $list
        }
    }
    if ($node.GetType().Name -eq 'PSCustomObject')
    { 
        $m = Get-Member -InputObject $node -MemberType 'NoteProperty'
        $m | ForEach-Object {
            $name = $_.Name
            Write-Debug ("-"+"."*2*$script:ind + "$name")
            if ($name.Length -gt 0)
            {
                $name = $name -replace "'", "''"
                Invoke-Expression "`$in = `$node.`'$name`'"
                Find-RefObject -node $in -list $list
            }
        }
    }
    $script:ind--
}


function Get-ReferencedObjects {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [AdfObject] $obj
    )
    
    Write-Debug "BEGIN: Get-ReferencedObjects(obj=$obj)"

    $script:ind = 0
    [System.Collections.ArrayList] $arr = [System.Collections.ArrayList]::new()
    #$arr = Find-RefObject -node $obj.Body -list $arr
    Find-RefObject -node $obj.Body -list $arr
    
    Write-Debug "END: Get-ReferencedObjects()"
    return $arr
}
