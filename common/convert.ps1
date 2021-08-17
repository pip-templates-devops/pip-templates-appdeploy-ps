function ConvertTo-EnvHashtable 
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$False, Position = 0, ValueFromPipeline=$True)]
        [Object] $InputObject = $null
    )
    process 
    {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [Hashtable]) 
        {
            $InputObject
        } 
        elseif ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) 
        {
            $collection = 
            @(
                foreach ($object in $InputObject) { ConvertTo-EnvHashtable $object }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject]) 
        {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties) 
            {
                $hash[$property.Name] = ConvertTo-EnvHashtable $property.Value
            }

            $hash
        }
        else 
        {
            $InputObject
        }
    }
}

function Get-EnvAwsOutput
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [Array[]] $InputObject
    )

    # define keys fo key and value 
    $keyParam = 'OutputKey'
    $valueParam = 'OutputValue'
    $result = New-Object System.Collections.Hashtable

    if ($null -eq $InputObject) { 
        Write-Host 'Outputs is null'

        return $null 
    }

    foreach($item in $InputObject) {
        $newKey = ($item | Select-Object -ExpandProperty $keyParam)
        $newValue =  ($item | Select-Object -ExpandProperty $valueParam)

        if ($null -ne $newKey) {
            $result[$newKey] = $newValue
        }
    } 
 
    return $result
}
