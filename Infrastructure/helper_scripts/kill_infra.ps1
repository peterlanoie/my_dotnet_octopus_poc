param(
    $project = "RandomQuotes",
    $role = "web-server",
    $octoUrl = "",
    $octoEnvId = "",
    $octoApiKey = ""
)

$ErrorActionPreference = "Stop"

# Setting default values for parameters

$missingParams = @()

if ($octoApiKey -like ""){
    try {
        $octoApiKey = $OctopusParameters["API_KEY"]
        Write-Output "Found value for octoApiKey from Octopus variables." 
    }
    catch {
        $missingParams = $missingParams + "-octoApiKey"
    }
}

if ($octoEnvId -like ""){
    try {
        $octoEnvId = $OctopusParameters["Octopus.Environment.Id"]
        Write-Output "Found value for octoEnv from Octopus variables: $octoEnv" 
    }
    catch {
        $missingParams = $missingParams + "-octoEnvId"
    }
}

if ($octoUrl -like ""){
    try {
        $octoUrl = $OctopusParameters["Octopus.Web.BaseUrl"]
        Write-Output "Found value for octoUrl from Octopus variables: $octoEnv" 
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

Write-Output "project is : $project"
Write-Output "octoUrl is : $octoUrl"
Write-Output "octoEnvId is : $octoEnvId"
if ($octoApiKey.Length -gt 0){
    Write-Output "octoApiKey is provided."
}

function Get-Instances {
    # Using AWS PowerShell to find target instances
    $targetStates = @("pending", "running")
    $instances = (Get-EC2Instance -Filter @{Name="tag:$project";Values=$octoEnvId}, @{Name="instance-state-name";Values=$targetStates}).Instances
    return $instances
}

function Get-Targets {
    # Calling the Octopus API to find target machines
    $header = @{ "X-Octopus-ApiKey" = $APIKey }
    $environment = (Invoke-WebRequest "$octoUrl/api/environments/$octoEnvId" -Headers $header -UseBasicParsing).content | ConvertFrom-Json
    $environmentMachines = $environment.Links.Machines.Split("{")[0]
    $machines = ((Invoke-WebRequest ($octoUrl + $environmentMachines) -Headers $header -UseBasicParsing).content | ConvertFrom-Json).items
    $targets = $machines | Where-Object {$role -in $_.Roles}
    return $targets
}

$instancesToKill = Get-Instances
$numOfInstancesToKill = $instancesToKill.Count
Write-Output "Number of instances to kill: $numOfInstancesToKill" 

$targetsToKill = Get-Targets
$numOfTargetsToKill = $targetsToKill.Count
Write-Output "Number of targets to kill: $numOfTargetsToKill" 

