function Get-AppComponent
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [hashtable] $Manifest,

        [Parameter(Mandatory=$true, Position=1)]
        [string] $Component
    )

    foreach ($componentObj in $Manifest.components) {
        if ($componentObj.name -eq $Component) {
            return $componentObj
        }
    }

    return $null
}