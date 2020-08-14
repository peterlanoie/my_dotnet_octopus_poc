param(
    $count = 1,
    $instanceType = "t2.micro", # 1 vCPU, 1GiB Mem, free tier elligible: https://aws.amazon.com/ec2/instance-types/
    $ami = "ami-0216167faf008006e", # Microsoft Windows Server 2019 Base with Containers
    $tagName = "octo_demobox",
    $tagValue = (Get-Date -Format "yyyy-MM-dd - HH:mm:ss"),
    $octoUrl = $OctopusParameters["Octopus.Web.ServerUri"],
    $octoEnv = $OctopusParameters["Octopus.Environment.Name"],
    [Switch]$DeployTentacle
)

$ErrorActionPreference = "Stop"

Write-Output "Installed AWS tools version:"
Get-AWSPowerShellVersion

# Preparing startup script for VM
if ($DeployTentacle){
    $userDataFile = "VM_UserData_With_Tentacle_Installation.ps1"
}
else {
    $userDataFile = "VM_UserData.ps1"
}
$userDataPath = "$PSScriptRoot\$userDataFile"
$userData = Get-Content -Path $userDataPath -Raw

# Variable substitution for UserData script
$userData = $userData.replace("__OCTOPUSURL__",$octoUrl)
$userData = $userData.replace("__ENV__",$octoEnv)

if (Test-Path $userDataPath){
    Write-Output "    Reading UserData (VM startup script) from $userDataPath."
}
else {
    Write-Error "No UserData (VM startup script) found at $userDataPath!"
}
# Base 64 encoding the setup script. More info here: 
# https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2-windows-user-data.html
Write-Output "    Base 64 encoding UserData."
$encodedUserData = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($userData))

# Checking how many instances are already running
Write-Output "    Checking how many instances are already running..."
$acceptableStates = @("pending", "running")
$PreExistingInstances = (Get-EC2Instance -Filter @{Name="tag:$tagName";Values=$tagValue}, @{Name="instance-state-name";Values=$acceptableStates}).Instances 
$before = $PreExistingInstances.count
Write-Output "      $before instances are already running." 
$totalRequired = $count - $PreExistingInstances.count
if ($totalRequired -lt 0){
    $totalRequired = 0
}
Write-Output "      $totalRequired more instances required." 

if ($totalRequired -gt 0){
    Write-Output "    Launching $totalRequired instances of type $instanceType and ami $ami."
    

    Write-Output "      Instances will each have tag $tagName with value $tagValue."

    $NewInstance = New-EC2Instance -ImageId $ami -MinCount $totalRequired -MaxCount $totalRequired -InstanceType $instanceType -UserData $encodedUserData -KeyName octopus-demobox -SecurityGroup octopus-demobox -IamInstanceProfile_Name octopus-demobox

    # Tagging all the instances
    ForEach ($InstanceID  in ($NewInstance.Instances).InstanceId){
        New-EC2Tag -Resources $( $InstanceID ) -Tags @(
            @{ Key=$tagName; Value=$tagValue}
        );
    }
}
# Initializing potential error data
$oops = $false
$err = "There is a problem with the following instances: "

# Checking if it worked
Write-Output "    Verifying that all instances have been/are being created: "
$instances = (Get-EC2Instance -Filter @{Name="tag:$tagName";Values=$tagValue}, @{Name="instance-state-name";Values=$acceptableStates}).Instances

ForEach ($instance in $instances){
    $id = $instance.InstanceId
    $state = $instance.State.Name
    Write-Output "      Instance $id is in state: $state"
}

if ($instances.count -ne $count){
    $errmsg = "Expected to see $count instances, but actually see " + $instances.count + " instances."
    Write-Warning "$errmsg"
    $err = $err + ". Also, $errmsg"
    $oops = $true
}

# Logging results
if ($oops){
    Write-Error $err
} else {
    $msg = "    " + $instances.count + " instances running successfully."
    Write-Output $msg
}
