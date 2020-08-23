param(
    $project = "",
    $role = "web-server", # Note, in future we will migrate to roles in format "RandomQuotes-web"
                          # When that happens we can infer role from $project and kill all machines
                          # That match the pattern "$project-*"
    $octoUrl = "",
    $octoEnvName = "",
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

if ($project -like ""){
    try {
        $project = $OctopusParameters["Octopus.Project.Name"]
        Write-Output "    Found value for project from Octopus variables: $project" 
    }
    catch {
        $missingParams = $missingParams + "-project"
    }
}

if ($octoEnvName -like ""){
    try {
        $octoEnvName = $OctopusParameters["Octopus.Environment.Name"]
        Write-Output "    Found value for octoEnv from Octopus variables: $octoEnvName" 
    }
    catch {
        $missingParams = $missingParams + "-octoEnvName"
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

$octoApiHeader = @{ "X-Octopus-ApiKey" = $octoApiKey }

# Finding the EnvironmentId

$environments = (Invoke-WebRequest "$octoUrl/api/environments" -Headers $octoApiHeader -UseBasicParsing).content | ConvertFrom-Json

$octoEnvId = ""
foreach ($e in $environments.Items){
    if (($e.Name -Like $octoEnvName) -and ($e.SpaceId -Like $spaceId)){ # Need to check against spaceId as well in case another space has an env with the same name
        $octoEnvId = $e.Id
    }
}

if ($octoEnvId -eq ""){
    Write-Error "Unable to find and environment Id for environment name: $octoEnvName"
}
else {
    Write-Output "      Environment Id for $octoEnvName is: $octoEnvId"
}

function Get-Instances {
    # Using AWS PowerShell to find target instances
    $targetStates = @("pending", "running")
    $instances = (Get-EC2Instance -Filter @{Name="tag:$project";Values=$octoEnvName}, @{Name="instance-state-name";Values=$targetStates}).Instances
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
Write-Output "    Number of instances to kill: $numOfInstancesToKill" 
Write-Output $instancesToKill.InstanceId

if ($numOfInstancesToKill -ne 0){
    # Using AWS PowerShell to kill all the target instances
    ForEach ($instance in $instancesToKill){
        $id = $instance.InstanceId
        Write-Output "      Removing instance $id"
        Remove-EC2Instance -InstanceId $id -Force
    }
    
    # Verifying that all instances are dead
    $remainingInstances = Get-Instances
    $numOfInstancesToKill = $remainingInstances.Count
    Write-Output "    Number of remaining instances: $numOfInstancesToKill" 
}

$targetsToKill = Get-Targets
$numOfTargetsToKill = $targetsToKill.Count
Write-Output "    Number of targets to kill: $numOfTargetsToKill" 
Write-Output $targetsToKill.id

if ($numOfTargetsToKill -ne 0){
    # Killing all the targerts using the Octo API
    ForEach ($target in $targetsToKill){
        $id = $target.id
        Write-Output "      Removing target $id"
        Invoke-RestMethod -Uri "$octoUrl/api/machines/$id" -Headers $octoApiHeader -Method Delete
    }

    # Verifying that all targets are dead
    $remainingTargetsToKill = Get-Targets
    $numOfTargetsToKill = $remainingTargetsToKill.Count
    Write-Output "    Number of targets to kill: $numOfTargetsToKill" 
}

if (($numOfInstancesToKill -ne 0) -or ($numOfTargetsToKill -ne 0)){
    Write-Error "Not all the EC2 instances / Octopus target manchines have been successfully killed."
}
else {
    Write-Host "    SUCCESS! All EC2 instances and Octopus target manchines for project $project in environment $octoEnvName have been killed."
}