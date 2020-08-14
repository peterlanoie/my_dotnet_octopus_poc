<powershell>
# If for whatever reason this doesn't work, check this file:
$log = "C:\StartupLog.txt"
Write-Output " Creating log file at $log"
Start-Transcript -path $log -append

# Creating RDP and Octopus users
Write-Output "Creating users"
$rdpUser = "student"
$rdpPwd = ConvertTo-SecureString "D3vOpsRocks!" -AsPlainText -Force
$octoUser = "octopus"
$octoPwd = ConvertTo-SecureString "5re4lsoRocks!" -AsPlainText -Force
function create-user {
    param ($user, $password)
    Write-Output "    Creating a user for RDP sessions: $user."
    New-LocalUser -Name $user -Password $password -AccountNeverExpires | out-null
    Write-Output "    Making $user an admin."
    Add-LocalGroupMember -Group "Administrators" -Member $user
}
create-user -user $rdpUser -password $rdpPwd
create-user -user $octoUser -password $octoPwd

Write-Output "Enabling Web-Server role for hosting websites"
Install-WindowsFeature -name Web-Server -IncludeManagementTools
</powershell>