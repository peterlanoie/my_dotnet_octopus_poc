param(
    $count = 1,
    $instanceType = "t2.micro", # 1 vCPU, 1GiB Mem, free tier elligible: https://aws.amazon.com/ec2/instance-types/
    $ami = "ami-0216167faf008006e", # Microsoft Windows Server 2019 Base with Containers
    $tagName = "RandomQuotes",
    $tagValue = "Created manually",
    $octoUrl = "",
    $octoEnv = "",
    [Switch]$DeployTentacle,
    [Switch]$Wait,
    $timeout = 1200 # seconds
)

$ErrorActionPreference = "Stop"

# Reading VM_UserData
$userDataFile = "VM_UserData.ps1"
$userDataPath = "$PSScriptRoot\$userDataFile"
$userData = Get-Content -Path $userDataPath -Raw

# Preparing startup script for VM
if ($DeployTentacle){
    # If deploying tentacle, uncomment the deploy tentacle script
    $userData = $userData.replace("<# DEPLOY TENTACLE"," ")
    $userData = $userData.replace("DEPLOY TENTACLE #>"," ")
    # And substitute the octopus URL and environment
    $userData = $userData.replace("__OCTOPUSURL__",$octoUrl)
    $userData = $userData.replace("__ENV__",$octoEnv)
}

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
Write-Output "    Checking how many instances are already running with tag $tagName and value $tagValue..."
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
    $msg = "    " + $instances.count + " instances have been launched successfully."
    Write-Output $msg
}

if ($Wait){
    $allRunning = $false
    $allRegistered = $false
    $runningWarningGiven = $false
    $registeredWarningGiven = $false

    Write-Output "    Waiting for instances to start. (This normally takes about 30 seconds.)"
    $stopwatch =  [system.diagnostics.stopwatch]::StartNew()
    
    While (-not $allRunning){
        $time = [Math]::Floor([decimal]($stopwatch.Elapsed.TotalSeconds))
        
        if ($time -gt $timeout){
            Write-Error "Timed out at $time seconds. Timeout currently set to $timeout seconds. There is a parameter on this script to adjust the default timeout."
        }
        
        if (($time -gt 60) -and (-not $runningWarningGiven)){
            Write-Warning "EC2 instances are taking an unusually long time to start."
            $runningWarningGiven = $true
        }
        
        $runningInstances = (Get-EC2Instance -Filter @{Name="tag:$tagName";Values=$tagValue}, @{Name="instance-state-name";Values="running"}).Instances
        $NumRunning = $runningInstances.count
        
        if ($NumRunning -eq $count){
            $allRunning = $true
            Write-Output "      $time seconds: All instances are running!"
            ForEach ($instance in $runningInstances){
                $id = $instance.InstanceId
                $ip = $instance.PublicIpAddress
                Write-Output "        Instance $id is available at the public IP: $ip"
            }
            break
        }
        else {
            Write-Output "      $time seconds: $NumRunning out of $count instances are running."
        }

        Start-Sleep -s 10
    }
    
    if ($deployTentacle){
        $machineNames = @()
    
        Write-Output "    Waiting for instances to register with Octopus Server. (This normally takes 6 or 7 minutes.)"
        $stopwatch.Restart()

        While (-not $allRegistered){
            $time = [Math]::Floor([decimal]($stopwatch.Elapsed.TotalSeconds))

            if ($time -gt $timeout){
                Write-Error "Timed out at $time seconds. Timeout currently set to $timeout seconds. There is a parameter on this script to adjust the default timeout."
            }
        
            if (($time -gt 600) -and (-not $registeredWarningGiven)){
                Write-Warning "Machines are taking an unusually long time to register."
                $registeredWarningGiven = $true
            }
            
            $APIKey = $OctopusParameters["API_KEY"]
            $Role = "web-server"
        
            # Authenticating to the API
            $header = @{ "X-Octopus-ApiKey" = $APIKey }

            # Calling the API to find get machine data
            $envID = $OctopusParameters["Octopus.Environment.Id"]
            $environment = (Invoke-WebRequest "$octoUrl/api/environments/$envID" -Headers $header -UseBasicParsing).content | ConvertFrom-Json
            $environmentMachines = $Environment.Links.Machines.Split("{")[0]
            $machines = ((Invoke-WebRequest ($octoUrl + $environmentMachines) -Headers $header -UseBasicParsing).content | ConvertFrom-Json).items
            $MachinesInRole = $machines | Where-Object {$Role -in $_.Roles}
             
            $NumRegistered = $MachinesInRole.Count
            
            if ($NumRegistered -gt $machineNames.Count){
                ForEach ($m in $MachinesInRole){
                    if ($m.Name -notin $machineNames.Name){
                        $name = $m.Name
                        $uri = $m.URI
                        Write-Output "        Machine $name registered with URI $uri"
                        $machineNames += $name
                    }
                }
            }
        
            if ($NumRegistered -ge $count){
                $allRegistered = $true
                Write-Output "      $time seconds: $NumRegistered out of $count instances are registered."
                Write-Output "    SUCCESS! All $count machines are registered!"
                break
            }
            else {
                Write-Output "      $time seconds: $NumRegistered out of $count instances are registered."
            }
            Start-Sleep -s 30
        }
    }
}
