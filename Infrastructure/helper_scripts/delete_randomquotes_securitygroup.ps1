param(
    $securityGroupName = "RandomQuotes"
)

$ErrorActionPreference = "Stop"  

# Helper function to see if security group exists
function Test-SecurityGroup {
    param (
        $name
    )
    try {
        Get-EC2SecurityGroup -GroupName $name | out-null
        return $true
    }
    catch {
        return $false
    }
}

# Deleting security group
$secGroupExistsBefore = Test-SecurityGroup $securityGroupName
if ($secGroupExistsBefore) {
    Write-Output "    Security group exists in EC2."
    Write-Output "    Deleting security group: $securityGroupName"
    $attempt = 1
    $totalAttempts = 20
    $waitTime = 5
    while ($attempt -lt $totalAttempts){
        Write-Output "      Attempt $attempt / $totalAttempts to delete security group: $securityGroupName"
        try {
            Remove-EC2SecurityGroup -GroupName $securityGroupName -Force
            break
        }
        catch {
            Write-Output "        Failed to remove security group. Error was:"
            $lastError = $Error[0]
            Write-Output "          $lastError"
            if ($attempt -eq 1) {
                Write-Output "        (We probably need to wait about a minute for the instances to shut down.)"
            }
            if ($attempt -lt $totalAttempts) {
                Write-Output "        Waiting $waitTime seconds then trying again."
                Start-Sleep -s $waitTime
            }
            else {
                Write-Error "Failed to delete security group. Ran out of attempts. If it was dependencies, ensure all instances are terminated, then try again."
            }
        }
        $attempt = $attempt + 1
    }
}
else {
    "    $securityGroupName security group does not exist in EC2. No need to delete it."
}

# Verifying security group deleted
$secGroupExistsAfter = Test-SecurityGroup $securityGroupName
if ($secGroupExistsBefore -and $secGroupExistsAfter) {
    Write-Error "    Failed to delete security group: $securityGroupName"
}
if ($secGroupExistsBefore -and -not $secGroupExistsAfter) {
    Write-Output "    Security group successfully deleted."
}
