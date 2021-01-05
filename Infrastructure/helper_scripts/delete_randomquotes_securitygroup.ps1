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
    Remove-EC2SecurityGroup -GroupName $securityGroupName -Force
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
