param(
    $project = "RandomQuotes",
    $role = "web-server", # Note, in future we will migrate to roles in format "RandomQuotes-web"
                          # When that happens we can infer role from $project and kill all machines
                          # That match the pattern "$project-*"
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
        $octoUrl = $OctopusParameters["Octopus.Web.ServerUri"]
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

$octoApiHeader = @{ "X-Octopus-ApiKey" = $octoApiKey }

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
    $environment = (Invoke-WebRequest "$octoUrl/api/environments/$octoEnvId" -Headers $octoApiHeader -UseBasicParsing).content | ConvertFrom-Json
    $environmentMachines = $environment.Links.Machines.Split("{")[0]
    $machines = ((Invoke-WebRequest ($octoUrl + $environmentMachines) -Headers $octoApiHeader -UseBasicParsing).content | ConvertFrom-Json).items
    $targets = $machines | Where-Object {$role -in $_.Roles}
    return $targets
}

$instancesToKill = Get-Instances
$numOfInstancesToKill = $instancesToKill.Count
Write-Output "Number of instances to kill: $numOfInstancesToKill" 

$targetsToKill = Get-Targets
$numOfTargetsToKill = $targetsToKill.Count
Write-Output "Number of targets to kill: $numOfTargetsToKill" 

if ($numOfInstancesToKill -ne 0){
    # Using AWS PowerShell to kill all the target instances
    ForEach ($instance in $instancesToKill){
        $id = $instance.id
        Write-Output "Removing instance $id"
        Remove-EC2Instance -InstanceId $id
    }
    
    # Verifying that all instances are dead
    $remainingInstances = Get-Instances
    $numOfInstancesToKill = $remainingInstances.Count
    Write-Output "Number of remaining instances: $numOfInstancesToKill" 
}

if ($numOfTargetsToKill -ne 0){
    # Killing all the targerts using the Octo API
    ForEach ($target in $targetsToKill){
        $id = $target.id
        Write-Output "Removing target $id"
        Invoke-RestMethod -Uri "$octoUrl/api/machines/$id" -Headers $octoApiHeader -Method Delete
    }

    # Verifying that all targets are dead
    $remainingTargetsToKill = Get-Targets
    $numOfTargetsToKill = $remainingTargetsToKill.Count
    Write-Output "Number of targets to kill: $numOfTargetsToKill" 
}

if (($numOfInstancesToKill -ne 0) -or ($numOfTargetsToKill -ne 0)){
    Write-Error "Not all the EC2 instances / Octopus target manchines have been successfully killed."
}
else {
    Write-Host "SUCCESS! All EC2 instances and Octopus target manchines for project $project in environment $octoEnv have been killed."
}