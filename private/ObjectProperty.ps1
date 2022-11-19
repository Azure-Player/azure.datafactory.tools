function Update-ObjectProperty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [PSCustomObject] $obj, 
        [Parameter(Mandatory)] [string] $path, 
        [Parameter(Mandatory)] [string] $value
    )
    
    Invoke-Expression "`$fieldType = `$obj.$path.GetType()"
    Write-Debug "Type of field [$path] = $fieldType"
    if ($fieldType -eq [String]) {
        Write-Debug "Setting as String value"
        $exp = "`$obj.$path = `"$value`""
    } elseif ($fieldType -eq [Boolean]) {
        Write-Debug "Setting as Boolean value"
        $exp = "`$obj.$path = `$$value"
    } elseif ($fieldType -eq [DateTime]) {
        Write-Debug "Setting as DateTime value"
        $exp = "`$obj.$path = `"$value`""
    } elseif ($fieldType -eq [System.Management.Automation.PSCustomObject]) {
        Write-Debug "Setting as json value"
        $jvalue = ConvertFrom-Json $value
        $exp = "`$obj.$path = `$jvalue"
    } else {
        Write-Debug "Setting as numeric value"
        $exp = "`$obj.$path = $value"
    }
    Invoke-Expression "$exp"

}

function Remove-ObjectProperty {
[CmdletBinding()]
param (
    [Parameter(Mandatory)] [PSCustomObject] $obj, 
    [Parameter(Mandatory)] [string] $path
)

    Write-Debug "Removing property: $path"

    $arr = $path.Split(".")
    $root = $arr[0]
    if ($arr.Count -eq 1) { $path = "" } else { $path = ($arr[1..($arr.Length-1)] -join '.') }

    if ($arr.Count -gt 1) { 
        Remove-ObjectProperty -obj $obj.$root -path $path
    }
    else
    {
        $obj.PSObject.Properties.Remove($root)
    }
}
    
function Add-ObjectProperty {
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)] [PSCustomObject] $obj, 
    [Parameter(Mandatory = $true)] [string] $path, 
    [Parameter(Mandatory = $true)] [string] $value
)

    Write-Debug "Adding new property: $path"

    $arr = $path.Split(".")
    $root = $arr[0]
    if ($arr.Count -eq 1) { $path = ""} else { $path = ($arr[1..($arr.Length-1)] -join '.') }

    if ($obj.PSobject.Properties.Name -contains "$root" -and $path)
    {
        Add-ObjectProperty -obj $obj.$root -path $path -value $value
    }
    elseif ($arr.Count -gt 1)
    { 
        $obj | Add-Member -NotePropertyName $root -NotePropertyValue (New-Object "PSCustomObject")
        Add-ObjectProperty -obj $obj.$root -path $path -value $value  
    }
    else 
    {
        $obj | Add-Member -NotePropertyName $root -NotePropertyValue $value
    }
}

