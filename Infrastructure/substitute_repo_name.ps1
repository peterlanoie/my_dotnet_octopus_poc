param (
    $repo = "dlmconsultants/my_dotnet_octopus_poc"
)
$ErrorActionPreference = "Stop"

$repoSplits = $repo -split "/"
$repoOwner = $repoSplits[0]
$repoName = $repoSplits[1]

$userDataFile = "VM_UserData.ps1"
$userDataPath = "$PSScriptRoot\helper_scripts\$userDataFile"
$oldUserData = Get-Content -Path $userDataPath -Raw

$userDataWithOwner = $oldUserData.replace("__REPOOWNER__",$repoOwner)
$newUserData = $userDataWithOwner.replace("__REPONAME__",$repoName)

Set-Content -Path $userDataPath  -Value $newUserData