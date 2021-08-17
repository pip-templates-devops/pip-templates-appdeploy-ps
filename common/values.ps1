function Get-EnvMapValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [object] $Map,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Key,
        [Parameter(Mandatory=$false, Position=2)]
        [object] $Default
    )

    $names = $Key.Split('.')
    $obj = $map

    foreach ($name in $names) {
        if ($obj -eq $null) {
            break
        } elseif ($obj -is [array]) {
            $index = [convert]::ToInt32($name, 10)
            $obj = $obj[$index]
        } elseif ($obj -is [hashtable]) {
            $obj = $obj[$name]
        } else {
            throw "Cannot get value by key $name. The parent property must be an array or hashtable"
        }
    }

    if ($obj -eq $null) {
        $obj = $Default
    }

    Write-Output $obj
}

function Set-EnvMapValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [object] $Map,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Key,
        [Parameter(Mandatory=$true, Position=2)]
        [object] $Value
    )

    $names = $key.Split('.')

    if ($names.Length -le 1) {
        if ($map -is [array]) {
            $index = [convert]::ToInt32($key, 10)
            $map[$key] = $value
        } else {
            $map[$key] = $value
        } 
        return
    }

    $name = $names[0]
    if ($map -is [array]) {
        $index = [convert]::ToInt32($name, 10)
        $nestedMap = $map[$index]
        if ($nestedMap -eq $null) {
            $nestedMap = @{}
            $map[$index] = $nestedMap
        }
    } else {
        $nestedMap = $map[$name]
        if ($nestedMap -eq $null) {
            $nestedMap = @{}
            $map[$name] = $nestedMap
        }
    } 

    $nestedKey = Join-String -InputObject $names[1..($names.Length-1)] -Separator "."
    Set-EnvMapValue -Map $nestedMap -Key $nestedKey -Value $Value    
}

function Get-EnvMapKeys
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [object] $Map
    )

    $keys = @()
    if ($map -is [array]) {
        for ($index = 0; $index -lt $map.Length; $index++) {
            $nestedMap = $map[$index]
            $nestedKeys = Get-EnvMapKeys -Map $nestedMap
            if ($nestedKeys.Length -eq 0) {
                $keys = $keys + $index.ToString()
            } else {
                foreach ($nestedKey in $nestedKeys) {
                    $key = $index.ToString() + "." + $nestedKey
                    $keys = $keys + $key
                }
            }
        }
    } elseif ($map -is [hashtable]) {
        foreach ($key in $map.Keys) {
            $nestedMap = $map[$key]
            $nestedKeys = Get-EnvMapKeys -Map $nestedMap
            if ($nestedKeys.Length -eq 0) {
                $keys = $keys + $key
            } else {
                foreach ($nestedKey in $nestedKeys) {
                    $compoundKey = $key + "." + $nestedKey
                    $keys = $keys + $compoundKey
                }
            }
        }
    }

    Write-Output $keys
}

function Set-EnvMapDefault
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [object] $Map,

        [Parameter(Mandatory=$true, Position=1)]
        [object] $Default
    )

    if ($Default -is [hashtable]) {
        if (-not ($Map -is [hashtable])) {
            return
        }

        foreach ($key in $Default.Keys) {
            $mapValue = $map[$key]
            $defaultValue = $default[$key]

            if ($mapValue -eq $null) {
                $map[$key] = $defaultValue
            } elseif ($mapValue -is [array] -and $mapValue.Length -eq 0) {
                $map[$key] = $defaultValue
            } elseif ($mapValue -is [hashtable]) {
                Set-EnvMapDefault -Map $mapValue -Default $defaultValue
            }
        }
    }
}

function Test-EnvMapValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [object] $Map,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Key
    )

    if ($map -eq $null) {
        Write-Output $false
        return
    }

    $names = $key.Split('.')

    if ($names.Length -le 1) {
        if ($map -is [array]) {
            $index = [convert]::ToInt32($key, 10)
            Write-Output $map.Length -gt $index
        } elseif ($map -is [hashtable]) {
            Write-Output $map.ContainsKey($key)
        } else {
            Write-Output $false
        } 
        return
    }

    $name = $names[0]
    if ($map -is [array]) {
        $index = [convert]::ToInt32($name, 10)
        $nestedMap = $map[$index]
    } else {
        $nestedMap = $map[$name]
    } 

    $nestedKey = Join-String -InputObject $names[1..($names.Length-1)] -Separator "."
    Test-EnvMapValue -Map $nestedMap -Key $nestedKey
}


function Remove-EnvMapValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [object] $Map,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Key
    )

    if ($map -eq $null) {
        return
    }

    $names = $key.Split('.')

    if ($names.Length -le 1) {
        if ($map -is [hashtable]) {
            $map.Remove($key)
        } 
        return
    }

    $name = $names[0]
    if ($map -is [array]) {
        $index = [convert]::ToInt32($name, 10)
        $nestedMap = $map[$index]
    } else {
        $nestedMap = $map[$name]
    } 

    $nestedKey = Join-String -InputObject $names[1..($names.Length-1)] -Separator "."
    Remove-EnvMapValue -Map $nestedMap -Key $nestedKey
}
