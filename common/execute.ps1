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
    [string] $Partition="root",

    [Parameter(Mandatory=$false, Position=5)]
    [string] $Task,

    [Parameter(Mandatory=$false, Position=6)]
    [string] $EnvironmentPrefix = "environment"
)

# Stop on error
$ErrorActionPreference = "Stop"

# Load common functions
$rootPath = $PSScriptRoot
if ($rootPath -eq "") { $rootPath = "." }
. "$($rootPath)/include.ps1"
$rootPath = $PSScriptRoot
if ($rootPath -eq "") { $rootPath = "." }

# Set flag to use a single manifest if a Deployment manifest is not set
$SingleManifestMode = $DeploymentManifestPath -eq ""

# Set default parameter values
if (($ResourcePath -eq $null) -or ($ResourcePath -eq ""))
{
    $ResourcePath = ConvertTo-EnvResourcePath -ConfigPath $ConfigPath
}
if (($ResoucePrefix -eq $null) -or ($ResourcePrefix -eq "")) 
{ 
    $ResoucePrefix = $ConfigPrefix 
}
$packagePath = (Get-Item $AppManifestPath).Directory.FullName

# Read config and resources
$config = Read-EnvConfig -ConfigPath $ConfigPath
$resources = Read-EnvResources -ResourcePath $ResourcePath

# Check for and fill in templated vars in appManifest, then read the appManifest
$appManifestTemplatePath = $AppManifestPath
$AppManifestPath = "$rootPath/../temp/app_manifest.json"
Build-EnvTemplate -InputPath $appManifestTemplatePath -OutputPath $AppManifestPath -Params1 $config -Params2 $resources
$appManifest = Read-AppManifest -ManifestPath $AppManifestPath

if(!$SingleManifestMode){
    # Check for and fill in templated vars in deploymentManifest, then read the deploymentManifest
    $deploymentManifestTemplatePath = $DeploymentManifestPath
    $DeploymentManifestPath = "$rootPath/../temp/deployment_manifest.json"
    Build-EnvTemplate -InputPath $deploymentManifestTemplatePath -OutputPath $DeploymentManifestPath -Params1 $config -Params2 $resources
    $deploymentManifest = Read-AppManifest -ManifestPath $DeploymentManifestPath
} else {
    # Just use the same manifest we created above
    $deploymentManifest = $appManifest
}

# Read applications array from resources file
$applications = Get-EnvMapValue -Map $resources -Key "applications"
if ($applications.Lenght -lt 2) {
    # Convert value to array if cmdlet returned an object 
    if ($applications -eq $null) {
        $applications = @()
    } else {
        $applications = @($applications)
    }
}

Write-Host "***** Performing $Task for application $($appManifest.name):$($appManifest.version) *****"

# Checking dependencies
$dependencies = $deploymentManifest.dependencies
if (($task -ne "uninstall") -and ($dependencies -ne $null)) {
    Write-Host "`n***** Checking dependencies... *****`n"

    foreach ($dependency in $dependencies) {
        $dependencyFromResources = $applications | Where-Object {$_.name -eq $dependency.name}
        if ($dependencyFromResources -eq $null) {
            Write-Error "Dependency $($dependency.name):$($dependency.version) - Missing"
        } else {
            # Check version
            if (Test-AppVersion -Version $dependencyFromResources.version -Pattern $Dependency.version) {
                Write-Host "Dependency $($dependency.name):$($dependency.version) - OK"
            } else {
                Write-Error "Dependency $($dependency.name):$($dependency.version) - Installed wrong version ($($dependencyFromResources.version))"
            }
        }
    }
}

# Defining recipe
$recipes = $deploymentManifest.$task
$universalRecipes = $false
if ($recipes -eq $null) {
    $recipes = $deploymentManifest["install-upgrade-uninstall"]
    $universalRecipes = $true
}
if ($recipes -eq $null) {
    throw "Manifest is missing $task declaration."   
}

# Find target environment in the deploymentManifest
$envType = (Get-EnvMapValue -Map $resources -Key "$EnvironmentPrefix.type")
$envVersion = (Get-EnvMapValue -Map $resources -Key "$EnvironmentPrefix.version")
if ($envType -eq $null -or $envVersion -eq $null) {
    throw "Environment type or version is missing in resources"
}

# Check for env type
$targetRecipe = $null
foreach ($recipe in $recipes) {
    foreach ($env in $recipe.environments) {
        if ($env.name -eq $envType) {
            $targetRecipe = $recipe
            break
        }
    }
}
if ($targetRecipe -eq $null) {
    throw "There are no steps for environment $envType in the deploymentManifest"
}

# Check for env version
foreach ($recipe in $recipes) {
    $deploymentManifestRecipeEnv = $recipe.environments | Where-Object {$_.name -eq $envType}
    if (!(Test-AppVersion -Version $envVersion -Pattern $deploymentManifestRecipeEnv.version)) {
        throw "Environment version ($envVersion) doesn't match pattern in deploymentManifest ($($deploymentManifestRecipeEnv.version))"
    }
}

Write-Host "`n***** Executing $Task actions for environment $envType... *****"

# Reverse uninstall steps for universal recipe (install-upgrade-uninstall)
$steps = $targetRecipe.steps
if ($task -eq "uninstall" -and $universalRecipes) {
    [array]::Reverse($steps)
}

$stepNumber = 0
$actionType = $null
# Executing custom actions changes the true root path, so we're saving it here
$rootPathBackup = $rootPath
foreach ($step in $steps) {
    $stepNumber++
    $actionPath = $null
    $actionName = $null
    if ($step.action -ne $null) {
        $actionType = "standard"
        $actionName = $step.action
        $actionPath = "$rootPath/../$actionName"
    } elseif ($step["custom-action"] -ne $null) {
        $actionType = "custom"
        $actionName = $step["custom-action"]
        $actionPath = "$packagePath/$actionName"
    } else {
        throw "Step #$stepNumber is missing 'action' or 'custom-action' in the deploymentManifest"
    }

    # Skip on certain tasks
    $executeOn = $step["execute-on"]
    if ($executeOn -ne $null) {
        if (-not ($executeOn -contains $task)) {
            continue;
        }
    }

    # Check if action exists
    if (-not (Test-Path -Path $actionPath)) {
        throw "$actionType action '$actionName' is not found at $actionPath."
    }
    if (-not (Test-Path -Path "$actionPath/$Task.ps1")) {
        throw "$actionType action '$actionName' does not support $Task steps"
    }

    # Define action parameters
    $actionParams = @{
        PackagePath=$packagePath;
        Partition=$Partition;
        TempPath="$rootPath/../temp"
    }

    Write-Host "`n***** Started $actionType action '$actionName' *****`n"

    . "$actionPath/$Task.ps1" -AppManifest $appManifest -DeploymentManifest $deploymentManifest -Config $config -Resources $resources -Context $step -Params $actionParams

    Write-Host "`n***** Completed $actionType action '$actionName' *****"

    # Executing custom actions changes the true root path, so here we're restoring it
    $rootPath = $rootPathBackup
}

if ($task -eq "install") {
    # Verify that app isn't installed already
    $app = $applications | Where-Object {$_.name -eq $appManifest.name}
    if ($app -eq $null) {
        # Add to applications array if install/upgrade
        $applications += @{
            name=$appManifest.name;
            version=$appManifest.version;
        }
    }
} elseif ($task -eq "upgrade") {
    # Update applications array on upgrade
    $app = $applications | Where-Object {$_.name -eq $appManifest.name}

    # Update version if it was changed
    if ($app.version -ne $appManifest.version) {
        $applications = $applications | Where-Object {$_.name -ne $appManifest.name}
        $applications += @{
            name=$appManifest.name;
            version=$appManifest.version;
        }
    }
} elseif ($task -eq "uninstall") {
    # Remove from applications array on uninstall
    $applications = $applications | Where-Object {$_.name -ne $appManifest.name}
    if ($applications.Lenght -lt 2) {
        # Convert value to array if cmdlet returned an object 
        $applications = @($applications)
    }
}

Set-EnvMapValue -Map $resources -Key "applications" -Value $applications
Write-EnvResources -ResourcePath $ResourcePath -Resources $resources
