
function Split-AppVersion
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Version
    )
    $versionPattern = "^(?<operator>~|\^|<=|<|=|>=|>)?(?<major>\d+|x|X|\*)(\.(?<minor>\d|x|X|\*))?(\.(?<bugfix>\d|x|X|\*))?(-(?<suffix>.+))?"

    if (!($Version -match $versionPattern)) {
        return $null
    }

    $result = @{
        operator=$Matches.operator;
        major=$Matches.major;
        minor=$Matches.minor;
        bugfix=$Matches.bugfix;
        suffix=$Matches.suffix;
    }

    if ($result.operator -eq $null -or $result.operator -eq "") {
        $result.operator = "="
    }
    if ($result.major -eq $null -or $result.major -eq "" -or $result.major -eq "x" -or $result.major -eq "X") {
        $result.major = "*"
    }
    if ($result.minor -eq $null -or $result.minor -eq "" -or $result.minor -eq "x" -or $result.minor -eq "X") {
        $result.minor = "*"
    }
    if ($result.bugfix -eq $null -or $result.bugfix -eq "" -or $result.bugfix -eq "x" -or $result.bugfix -eq "X") {
        $result.bugfix = "*"
    }

    return $result
}

function Get-AppVersionOperator
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Version
    )
    $versionParts = Split-AppVersion -Version $Version
    if ($versionParts -eq $null) {
        return $null
    }

    return $versionParts.operator
}

function Get-AppVersionMajor
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Version
    )
    $versionParts = Split-AppVersion -Version $Version
    if ($versionParts -eq $null) {
        return $null
    }

    return $versionParts.major
}
function Get-AppVersionMinor
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Version
    )
    $versionParts = Split-AppVersion -Version $Version
    if ($versionParts -eq $null) {
        return $null
    }

    return $versionParts.minor
}

function Get-AppVersionBugfix
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Version
    )
    $versionParts = Split-AppVersion -Version $Version
    if ($versionParts -eq $null) {
        return $null
    }

    return $versionParts.bugfix
}

function Test-AppVersion
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Version,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Pattern
    )

    $versionParts = Split-AppVersion -Version $Version
    if ($versionParts -eq $null) {
        return $false
    }

    $patternParts = Split-AppVersion -Version $Pattern
    if ($patternParts -eq $null) {
        return $false
    }

    switch ($patternParts.operator) {
        "~" {
            if ($versionParts.major -ne "*" -and $patternParts.major -ne "*" -and $versionParts.major -ne $patternParts.major) {
                return $false
            }
            if ($versionParts.minor -ne "*" -and $patternParts.minor -ne "*" -and $versionParts.minor -ne $patternParts.minor) {
                return $false
            }
            if ($versionParts.bugfix -ne "*" -and $patternParts.bugfix -ne "*" -and $versionParts.bugfix -lt $patternParts.bugfix) {
                return $false
            }
            return $true
        }
        "^" {
            if ($versionParts.major -ne "*" -and $patternParts.major -ne "*" -and $versionParts.major -ne $patternParts.major) {
                return $false
            }
            if ($versionParts.minor -ne "*" -and $patternParts.minor -ne "*" -and $versionParts.minor -lt $patternParts.minor) {
                return $false
            }
            if ($versionParts.bugfix -ne "*" -and $patternParts.bugfix -ne "*" -and $versionParts.bugfix -lt $patternParts.bugfix) {
                return $false
            }
            return $true
        }
        "<" {
            if ($versionParts.major -ne "*" -and $patternParts.major -ne "*" -and $versionParts.major -lt $patternParts.major) {
                return $true
            }
            if ($versionParts.major -ne "*" -and $patternParts.major -ne "*" -and $versionParts.major -gt $patternParts.major) {
                return $false
            }
            if ($versionParts.minor -ne "*" -and $patternParts.minor -ne "*" -and $versionParts.minor -lt $patternParts.minor) {
                return $true
            }
            if ($versionParts.minor -ne "*" -and $patternParts.minor -ne "*" -and $versionParts.minor -gt $patternParts.minor) {
                return $false
            }
            if ($versionParts.bugfix -ne "*" -and $patternParts.bugfix -ne "*" -and $versionParts.bugfix -lt $patternParts.bugfix) {
                return $true
            }
            if ($versionParts.bugfix -ne "*" -and $patternParts.bugfix -ne "*" -and $versionParts.bugfix -gt $patternParts.bugfix) {
                return $false
            }
            return $false
        }
        "<=" {
            if ($versionParts.major -ne "*" -and $patternParts.major -ne "*" -and $versionParts.major -lt $patternParts.major) {
                return $true
            }
            if ($versionParts.major -ne "*" -and $patternParts.major -ne "*" -and $versionParts.major -gt $patternParts.major) {
                return $false
            }
            if ($versionParts.minor -ne "*" -and $patternParts.minor -ne "*" -and $versionParts.minor -lt $patternParts.minor) {
                return $true
            }
            if ($versionParts.minor -ne "*" -and $patternParts.minor -ne "*" -and $versionParts.minor -gt $patternParts.minor) {
                return $false
            }
            if ($versionParts.bugfix -ne "*" -and $patternParts.bugfix -ne "*" -and $versionParts.bugfix -lt $patternParts.bugfix) {
                return $true
            }
            if ($versionParts.bugfix -ne "*" -and $patternParts.bugfix -ne "*" -and $versionParts.bugfix -gt $patternParts.bugfix) {
                return $false
            }
            return $true
        }
        "=" {
            if ($versionParts.major -ne "*" -and $patternParts.major -ne "*" -and $versionParts.major -lt $patternParts.major) {
                return $false
            }
            if ($versionParts.major -ne "*" -and $patternParts.major -ne "*" -and $versionParts.major -gt $patternParts.major) {
                return $false
            }
            if ($versionParts.minor -ne "*" -and $patternParts.minor -ne "*" -and $versionParts.minor -lt $patternParts.minor) {
                return $false
            }
            if ($versionParts.minor -ne "*" -and $patternParts.minor -ne "*" -and $versionParts.minor -gt $patternParts.minor) {
                return $false
            }
            if ($versionParts.bugfix -ne "*" -and $patternParts.bugfix -ne "*" -and $versionParts.bugfix -lt $patternParts.bugfix) {
                return $false
            }
            if ($versionParts.bugfix -ne "*" -and $patternParts.bugfix -ne "*" -and $versionParts.bugfix -gt $patternParts.bugfix) {
                return $false
            }
            return $true
        }
        ">=" {
            if ($versionParts.major -ne "*" -and $patternParts.major -ne "*" -and $versionParts.major -lt $patternParts.major) {
                return $false
            }
            if ($versionParts.major -ne "*" -and $patternParts.major -ne "*" -and $versionParts.major -gt $patternParts.major) {
                return $true
            }
            if ($versionParts.minor -ne "*" -and $patternParts.minor -ne "*" -and $versionParts.minor -lt $patternParts.minor) {
                return $false
            }
            if ($versionParts.minor -ne "*" -and $patternParts.minor -ne "*" -and $versionParts.minor -gt $patternParts.minor) {
                return $true
            }
            if ($versionParts.bugfix -ne "*" -and $patternParts.bugfix -ne "*" -and $versionParts.bugfix -lt $patternParts.bugfix) {
                return $false
            }
            if ($versionParts.bugfix -ne "*" -and $patternParts.bugfix -ne "*" -and $versionParts.bugfix -gt $patternParts.bugfix) {
                return $true
            }
            return $true
        }
        ">" {
            if ($versionParts.major -ne "*" -and $patternParts.major -ne "*" -and $versionParts.major -lt $patternParts.major) {
                return $false
            }
            if ($versionParts.major -ne "*" -and $patternParts.major -ne "*" -and $versionParts.major -gt $patternParts.major) {
                return $true
            }
            if ($versionParts.minor -ne "*" -and $patternParts.minor -ne "*" -and $versionParts.minor -lt $patternParts.minor) {
                return $false
            }
            if ($versionParts.minor -ne "*" -and $patternParts.minor -ne "*" -and $versionParts.minor -gt $patternParts.minor) {
                return $true
            }
            if ($versionParts.bugfix -ne "*" -and $patternParts.bugfix -ne "*" -and $versionParts.bugfix -lt $patternParts.bugfix) {
                return $false
            }
            if ($versionParts.bugfix -ne "*" -and $patternParts.bugfix -ne "*" -and $versionParts.bugfix -gt $patternParts.bugfix) {
                return $true
            }
            return $false
        }
        default {
            return $false
        }
    }
}
