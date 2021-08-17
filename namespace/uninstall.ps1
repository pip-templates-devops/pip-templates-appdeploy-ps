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
$rootPath = $PSScriptRoot
if ($rootPath -eq "") { $rootPath = "." }
$inputPath = "$rootPath/templates/namespace.yml"

$tempPath = $Params.TempPath
$outputPath = "$tempPath/namespace.yml"

$namespace = $Context.namespace
if ($namespace -eq $null) {
    throw "Namespace is missing in the action step"
}
# Delete namespace
$envType = Get-EnvMapValue -Map $config -Key "environment.type"
if ($envType -eq "edge") {
    # Delete docker network
    sudo docker network rm $namespace
} else {
    # Delete k8s namespace
    $templateParams = @{ 
        namespace=$namespace 
    }

    Build-EnvTemplate -InputPath $inputPath -OutputPath $outputPath -Params1 $templateParams

    kubectl delete -f $outputPath

    Remove-Item -Path $outputPath
}
