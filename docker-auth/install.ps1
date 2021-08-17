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
$dockerRegistry = (Get-EnvMapValue -Map $config -Key "docker.registry")
if ($dockerRegistry -eq $null) {
    $dockerRegistry = "ghcr.io"
}
$dockerUsername = (Get-EnvMapValue -Map $config -Key "docker.username")
$dockerPassword = (Get-EnvMapValue -Map $config -Key "docker.password")
$dockerEmail = (Get-EnvMapValue -Map $config -Key "docker.email")
if ($dockerUsername -eq $null -or $dockerPassword -eq $null -or $dockerEmail -eq $null) {
    throw "Docker registry connection parameters are missing in environment configuration."
}
$namespace = $Context.namespace
if ($namespace -eq $null) {
    throw "Namespace is missing in the action step"
}

# Login to private docker registry
$envType = Get-EnvMapValue -Map $config -Key "environment.type"
if ($envType -eq "edge") {
    # Docker login for edge medium env
    sudo docker login $dockerRegistry -u $dockerUsername -p $dockerPassword
} else {
    # Create k8s secret
    kubectl -n $namespace create secret docker-registry auth --docker-server=$dockerRegistry --docker-username=$dockerUsername --docker-password=$dockerPassword --docker-email=$dockerEmail
}
