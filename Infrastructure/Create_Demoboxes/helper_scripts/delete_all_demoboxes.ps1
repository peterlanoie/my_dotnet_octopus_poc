param(
    $tag = "manual"
)

# Helper function to query AWS and grab all the appropriate instance info
function Get-InstancesToKill { 
    $instances = (Get-EC2Instance -Filter @{Name="tag:Octo_Demobox";Values=$tag}).Instances 
    return $instances
}

# Finding out which instances need to be deleted
$instances = Get-InstancesToKill

# Terminating all the appropriate instances
Write-Output "*****************************"
$msg = "Attempting to delete " + $instances.count + " instances:"
Write-Output $msg
ForEach ($instance in $instances){
    $msg = "    Deleting " + $instance.InstanceId
    Write-Output $msg
    # Kill switch
    Remove-EC2Instance -InstanceId $instance.InstanceId -Force | out-null # omitting ugly output
}

# Initializing potential error info
$oops = $false
$err = "Failed to kill the following instances: "

# Checking if it worked
Write-Output "*****************************"
Write-Output "Verifying that all instances have been/are being terminated: "
$instances = Get-InstancesToKill
$acceptableStates = @("shutting-down", "terminated")

ForEach ($instance in $instances){
    $id = $instance.InstanceId
    $state = $instance.State.Name
    if ($state -notin $acceptableStates){
        Write-Warning "    Instance $id is in state: $state"
        $err = $err + "$id, "
        $oops = $true
    }
    else {
        Write-Output "    Instance $id is in state: $state"
    }
}
Write-Output "*****************************"
# Logging results
if ($oops){
    Write-Error $err
} else {
    $msg = "Successfully terminated " + $instances.count + " instances."
    Write-Output $msg
}
