function Find-RefObject($node, $list) {
    if ($null -ne $node.PSobject -and $node.PSobject.Properties.Name -contains 'referenceName' -and $node.PSobject.Properties.Name -contains 'type') {
        [string] $type = $node.type
        if ($type.EndsWith('Reference')) {
            $type = $type.Substring(0, $type.Length-9)
            #Write-Host "$type.$($node.referenceName)"
            $list.Add("$type.$($node.referenceName)") | Out-Null
        }
    }
    
    $m = Get-Member -InputObject $node -MemberType 'NoteProperty'
    $m | ForEach-Object {
        $name = $_.Name
        #Write-Verbose "Checking: $name"
        Invoke-Expression "`$in = `$node.`'$name`'"
        if ($in.GetType().Name -eq 'PSCustomObject')
        {
            Find-RefObject -node $in -list $list
        }
    }
}


function Get-ReferencedObjects {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [AdfObject] $obj
    )
    
    Write-Debug "BEGIN: Get-ReferencedObjects(obj=$obj)"

    [System.Collections.ArrayList] $arr = [System.Collections.ArrayList]::new()
    #$arr = Find-RefObject -node $obj.Body -list $arr
    Find-RefObject -node $obj.Body -list $arr
    
    Write-Debug "END: Get-ReferencedObjects()"
    return $arr
}
