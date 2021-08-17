#!/usr/bin/env pwsh

param
(
    [Alias("Manifest", "Application")]
    [Parameter(Mandatory=$true, Position=0)]
    [string] $AppManifestPath,

    [Alias("Deployment")]
    [Parameter(Mandatory=$false, Position=1)]
    [string] $DeploymentManifestPath,

    [Alias("Config")]
    [Parameter(Mandatory=$true, Position=2)]
    [string] $ConfigPath,

    [Alias("Resources")]
    [Parameter(Mandatory=$false, Position=3)]
    [string] $ResourcePath,

    [Parameter(Mandatory=$false, Position=4)]
    [string] $Partition="root"
)

# Load common functions
$rootPath = $PSScriptRoot
if ($rootPath -eq "") { $rootPath = "." }

if ($DeploymentManifestPath -ne "") {
    . "$($rootPath)/common/execute.ps1" -Manifest $AppManifestPath -Deployment $DeploymentManifestPath -Config $ConfigPath -Resources $ResourcePath -Partition $Partition -Task "install"
} else{
    # Use single manifest if Deployment manifest not set
    . "$($rootPath)/common/execute.ps1" -Manifest $AppManifestPath -Config $ConfigPath -Resources $ResourcePath -Partition $Partition -Task "install"
}
