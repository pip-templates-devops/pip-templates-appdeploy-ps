#!/usr/bin/env pwsh

param
(
    [Alias("Manifest", "Application")]
    [Parameter(Mandatory=$true, Position=0)]
    [hashtable] $AppManifest,

    [Alias("Deployment")]
    [Parameter(Mandatory=$false, Position=1)]
    [hashtable] $DeploymentManifest,

    [Parameter(Mandatory=$true, Position=2)]
    [hashtable] $Config,

    [Parameter(Mandatory=$true, Position=3)]
    [hashtable] $Resources,

    [Parameter(Mandatory=$true, Position=4)]
    [hashtable] $Context,

    [Parameter(Mandatory=$true, Position=5)]
    [hashtable] $Params
)

# Use single manifest if Deployment manifest not set
if ($DeploymentManifest -eq $null) {
    $DeploymentManifest = $AppManifest
}

# Reading parameters
$namespace = $Context.namespace
if ($namespace -eq $null) {
    throw "Namespace is missing in the action step"
}

# Logout from private registry
$envType = Get-EnvMapValue -Map $config -Key "environment.type"
if ($envType -eq "edge") {
    # Docker logout for edge medium env
    sudo docker logout $dockerRegistry
} else {
    # Delete k8s secret
    kubectl -n $namespace delete secret auth
}
