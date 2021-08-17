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

    [Parameter(Mandatory=$true, Position=4)]
    [string] $Version,

    [Parameter(Mandatory=$true, Position=5)]
    [string] $Namespace
)

# Use single manifest if Deployment manifest not set
if ($DeploymentManifestPath -eq "") {
    $DeploymentManifestPath = $AppManifestPath
}

# Stop on error
$ErrorActionPreference = "Stop"

# Load common functions
$rootPath = $PSScriptRoot
if ($rootPath -eq "") { $rootPath = "." }
. "$($rootPath)/common/include.ps1"
$rootPath = $PSScriptRoot
if ($rootPath -eq "") { $rootPath = "." }

# Set default parameter values
if (($ResourcePath -eq $null) -or ($ResourcePath -eq ""))
{
    $ResourcePath = ConvertTo-EnvResourcePath -ConfigPath $ConfigPath
}
if (($ResoucePrefix -eq $null) -or ($ResourcePrefix -eq "")) 
{ 
    $ResoucePrefix = $ConfigPrefix 
}

# Read config and resources
$config = Read-EnvConfig -ConfigPath $ConfigPath
$resources = Read-EnvResources -ResourcePath $ResourcePath

# Check for and fill in templated vars in appManifest, then read the appManifest
$appManifestTemplatePath = $AppManifestPath
$AppManifestPath = "$rootPath/temp/app_manifest.json"
Build-EnvTemplate -InputPath $appManifestTemplatePath -OutputPath $AppManifestPath -Params1 $config -Params2 $resources
$appManifest = Read-AppManifest -ManifestPath $AppManifestPath

# Check for and fill in templated vars in deploymentManifest, then read the deploymentManifest
$deploymentManifestTemplatePath = $DeploymentManifestPath
$DeploymentManifestPath = "$rootPath/temp/deployment_manifest.json"
Build-EnvTemplate -InputPath $deploymentManifestTemplatePath -OutputPath $DeploymentManifestPath -Params1 $config -Params2 $resources
$deploymentManifest = Read-AppManifest -ManifestPath $DeploymentManifestPath

# Verify appManifest version
if ($Version -ne $appManifest.version) {
    throw "Specified version ($Version) doesn't match to the appManifest version ($($appManifest.version))"
}

# Get components running in environment
$envType = Get-EnvMapValue -Map $config -Key "environment.type"
if ($envType -eq "edge" -or $envType -eq "maxinthebox") {
    # Docker env
    $envComponents = sudo docker ps --filter "network=$Namespace" --format '{{.Image}}'
} else {
    # K8S env
    $envComponents = kubectl get pods -n $namespace -o=jsonpath='{range .items[*]}{\"\n\"}{range .spec.containers[0]}{.image}{end}'
    # Remove duplicates (if replicas exist)
    $envComponents = $envComponents | Select-Object -Unique
    # Trim first empty item
    if ($envComponents[0] -eq "") {
        $envComponents = $envComponents[1..($envComponents.Length-1)]
    }
}

# Itterate each appManifest component
$appManifestComponents = $appManifest.components | Where-Object {$_.type -eq "container"}
foreach ($appManifestComponent in $appManifestComponents) {
    Write-Host "Processing component $($appManifestComponent.name)..."
    $image = "$($appManifestComponent.registry)/$($appManifestComponent.name)"
    $envComponentFullImage = $envComponents | Where-Object {$_ -match $image}
    if ($envComponentFullImage -eq $null) {
        # If env doesn't have component from appManifest throw an error
        throw "Component $($appManifestComponent.name) is missing in the environment."
    }
    $envComponentVersion = $envComponentFullImage.Split(":")[1]

    if ($appManifestComponent.version -ne $envComponentVersion) {
        Write-Host "Component $($appManifestComponent.name) uses image $envComponentFullImage, but version in appManifest is $($appManifestComponent.version)"
        Write-Host "Updating component version in the appManifest file..."
        $newComponent = $appManifest.components | Where-Object {$_.name -eq $appManifestComponent.name}
        $temp = $appManifest.components | Where-Object {$_.name -ne $appManifestComponent.name}
        $newComponent.version = $envComponentVersion
        $temp += $newComponent

        $sourceAppManifest = Read-AppManifest -ManifestPath $appManifestTemplatePath
        $sourceAppManifest.components = $temp

        $sourceAppManifest | ConvertTo-Json -Depth 20 | Set-Content -Path $appManifestTemplatePath
    }
}

# Verify that all components running in env present 
foreach ($envComponent in $envComponents) {
    $image = $envComponent.Split(":")[0]
    if (($appManifestComponents | Where-Object {"$($_.registry)/$($_.name)" -eq $image}) -eq $null) {
        Write-Host "Component with image $envComponent is running in environment, but missing in appManifest."
    }
}
