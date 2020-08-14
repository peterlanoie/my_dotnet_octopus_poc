# Creating RDP and Octopus users
Write-Output "  Creating users"
$rdpUser = "student"
$rdpPwd = ConvertTo-SecureString "D3vOpsRocks!" -AsPlainText -Force
$octoUser = "octopus"
$octoPwd = ConvertTo-SecureString "5re4lsoRocks!" -AsPlainText -Force
function New-User {
    param ($user, $password)
    Write-Output "    Creating a user: $user."
    New-LocalUser -Name $user -Password $password -AccountNeverExpires | out-null
    Write-Output "    Making $user an admin."
    Add-LocalGroupMember -Group "Administrators" -Member $user
}
New-User -user $rdpUser -password $rdpPwd
New-User -user $octoUser -password $octoPwd