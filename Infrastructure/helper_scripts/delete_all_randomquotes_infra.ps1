param(
    $project = "",
    $octoUrl = "",
    $octoApiKey = "",
    $spaceId = "Spaces-1" # If you are using the non-default space you will need to update this
)

$ErrorActionPreference = "Stop"

# Setting default values for parameters
$missingParams = @()

if ($octoApiKey -like ""){
    try {
        $octoApiKey = $OctopusParameters["API_KEY"]
        Write-Output "    Found value for octoApiKey from Octopus variables." 
    }
    catch {
        $missingParams = $missingParams + "-octoApiKey"
    }
}

if ($octoUrl -like ""){
    try {
        $octoUrl = $OctopusParameters["Octopus.Web.ServerUri"]
        Write-Output "    Found value for octoUrl from Octopus variables: $octoUrl" 
    }
    catch {
        $missingParams = $missingParams + "-octoUrl"
    }
}

if ($missingParams.Count -gt 0){
    $errorMessage = "Missing the following parameters: "
    foreach ($param in $missingParams) {
        $errorMessage += "$param, "
    }
    Write-Error $errorMessage
}

# API header for Octopus Deploy
$octoApiHeader = @{ "X-Octopus-ApiKey" = $octoApiKey }

# Finding all the environments
$environments = (Invoke-WebRequest "$octoUrl/api/environments" -Headers $octoApiHeader -UseBasicParsing).content | ConvertFrom-Json

# Deleting all the VMs and tentacles
ForEach-Object $envName in $environments {
    Write-Output "Executing $PSScriptRoot\kill_infra.ps1..."
    Write-Output "  Parameters: -octoEnvName $envName"
    & $PSScriptRoot\helper_scripts\kill_infra.ps1 -octoEnvName $envName
    Write-Output "*"
}