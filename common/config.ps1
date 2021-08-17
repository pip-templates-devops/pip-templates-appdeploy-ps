$path = $PSScriptRoot
if ($path -eq "") { $path = "." }

function Read-EnvConfig
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $ConfigPath
    )

    if (($ConfigPath -eq $null) -or ($ConfigPath -eq "")) {
        throw "Config path is not set. Execute <script>.ps1 -Config <config file>"
    }

    if (-not (Test-Path -Path $ConfigPath)) {
        throw "Config path $($ConfigPath) was not found"
    }

    # Read the config file
    # $Config = Get-Content -Path $ConfigPath | ConvertFrom-Json | ConvertTo-Hashtable
    $config = Get-Content -Path $ConfigPath | Out-String | ConvertFrom-Json | ConvertTo-EnvHashtable

    # Apply default configuration
    $defaultConfigPath = "$path/../config/default_config.json"
    if (Test-Path -Path $defaultConfigPath)
    {
        $defaultConfig = Get-Content -Path $defaultConfigPath | Out-String | ConvertFrom-Json | ConvertTo-EnvHashtable
        Set-EnvMapDefault -Map $config -Default $defaultConfig
    }

    Write-Output $config
}

function ConvertTo-EnvResourcePath
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $ConfigPath
    )

    $parent = Split-Path -Path $ConfigPath -Parent
    $file = Split-Path -Path $ConfigPath -Leaf
    $lastDotPos = $file.LastIndexOf('.')

    if($lastDotPos -gt -1)
    {
        $file = $file.Substring(0, $lastDotpos)
    }

    if ($file.Contains("config")) {
        $file = $file.Replace("config", "resources")
    } else {
        $file = $file + "_resources"
    }

    return $parent + "/" + $file + ".json"
}

function Read-EnvResources
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $ResourcePath
    )
    
    # If resources do not exist yet return an empty result
    if (($ResourcePath -eq $null) -or ($ResourcePath -eq "")) {
        return @{}
    }
    if (-not (Test-Path -Path $ResourcePath)) {
        return @{}
    }

    # Read the resources file
    # $Resources  = Get-Content -Path $Path | ConvertFrom-Json | ConvertTo-Hashtable
    $Resources = Get-Content -Path $ResourcePath | Out-String | ConvertFrom-Json | ConvertTo-EnvHashtable
    Write-Output $Resources
}

function Write-EnvResources
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $ResourcePath,
        [Parameter(Mandatory=$true, Position=1)]
        [hashtable] $Resources
    )

    # Write the content to resource file
    $Content = ConvertTo-Json $Resources
    Set-Content -Path $ResourcePath -Value $Content
}

function Read-AppManifest
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $ManifestPath
    )
    
    if (($ManifestPath -eq $null) -or ($ManifestPath -eq "")) {
        throw "Manifest path is not set. Execute <script>.ps1 -Manifest <manifest file>"
    }

    if (-not (Test-Path -Path $ManifestPath)) {
        throw "Manifest path $($ManifestPath) was not found"
    }

    # Read the manifest file
    # $Manifest = Get-Content -Path $ManifestPath | ConvertFrom-Json | ConvertTo-Hashtable
    $Manifest = Get-Content -Path $ManifestPath | Out-String | ConvertFrom-Json | ConvertTo-EnvHashtable

    Write-Output $Manifest
}
