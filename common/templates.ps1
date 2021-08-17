function ConvertFrom-EnvTemplate
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Template,
        [Parameter(Mandatory=$false, Position=1)]
        [hashtable] $Params1 = @{},
        [Parameter(Mandatory=$false, Position=2)]
        [hashtable] $Params2 = @{},
        [Parameter(Mandatory=$false, Position=3)]
        [switch] $Base64
    )

    $beginTag = [regex]::escape("<%=")
    $endTag = [regex]::escape("%>")
    $output = ""

    $Template = $Template -replace [environment]::newline, "`r"

    while ($Template -match "(?<pre>.*?)$beginTag(?<key>.*?)$endTag(?<post>.*)") {
        $Template = $matches.post
        $key = $matches.key.Trim()
        $value = Get-EnvMapValue -Map $Params1 -Key $key
        if ($value -eq $null) {
            $value = Get-EnvMapValue -Map $Params2 -Key $key
        }
        if ($value -is [array]) {
            $value = $value -join ", "
        } else {
            $value = $value + ""
            if ($Base64) {
                $value = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($value))
            }
        }
        $output += $matches.pre + $value
    }

    $output += $Template
    $output = $output -replace "`r", [environment]::newline 
    Write-Output $output
}

function Build-EnvTemplate
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $InputPath,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $OutputPath,
        [Parameter(Mandatory=$false, Position=2)]
        [hashtable] $Params1 = @{},
        [Parameter(Mandatory=$false, Position=3)]
        [hashtable] $Params2 = @{},
        [Parameter(Mandatory=$false, Position=4)]
        [switch] $Base64
    )

    $template = Get-Content -Path $InputPath | Out-String
    if ($template -ne "") {
        if ($Base64) {
            $value = ConvertFrom-EnvTemplate -Template $template -Params1 $Params1 -Params2 $Params2 -Base64 
        } else {
            $value = ConvertFrom-EnvTemplate -Template $template -Params1 $Params1 -Params2 $Params2
        }
    } else {
        $value = ""
    }
    Set-Content -Path $OutputPath -Value $value
}