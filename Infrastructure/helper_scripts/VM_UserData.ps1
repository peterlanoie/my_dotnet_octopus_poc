<powershell>
$ErrorActionPreference = "stop"

$startupDir = "C:\Startup"
$scriptsDir = "scripts"

if ((test-path $startupDir) -ne $true) {
  New-Item -ItemType "Directory" -Path $startupDir
}

Set-Location $startupDir

# If for whatever reason this doesn't work, check this file:
$log = ".\StartupLog.txt"
Write-Output " Creating log file at $log"
Start-Transcript -path $log -append

Set-Location $startupDir

if ((test-path $scriptsDir) -ne $true) {
  New-Item -ItemType "Directory" -Path $scriptsDir
}

Set-Location $scriptsDir

Function Get-Script{
  param (
    [Parameter(Mandatory=$true)][string]$script,
    [string]$owner = "__REPOOWNER__",
    [string]$repo = "__REPONAME__",
    [string]$branch = "main",
    [string]$path = "Infrastructure\UserDataDownloads"
  )
  $uri = "https://raw.githubusercontent.com/$owner/$repo/$branch/$path/$script"
  Write-Output "Downloading $script"
  Write-Output "  from: $uri"
  Write-Output "  to: .\$script"
  Invoke-WebRequest -Uri $uri -OutFile ".\$script" -Verbose
}

Write-Output "*"
Get-Script -script "setup_users.ps1"
Write-Output "Executing ./setup_users.ps1"
./setup_users.ps1

Write-Output "*"
Get-Script -script "setup_iis.ps1"
Write-Output "Executing ./setup_iis.ps1"
./setup_iis.ps1

Write-Output "*"
Get-Script -script "setup_dotnet_core.ps1"
Write-Output "Executing ./setup_dotnet_core.ps1"
./setup_dotnet_core.ps1

<# DEPLOY TENTACLE
$octopusServerUrl = "__OCTOPUSURL__"
$registerInEnvironments = "__ENV__"
$registerInRoles = "__ROLE__"

Write-Output "*"
Get-Script -script "install_tentacle.ps1"
Write-Output "Executing ./install_tentacle.ps1 -octopusServerUrl $octopusServerUrl -registerInEnvironments $registerInEnvironments" -registerInRoles $registerInRoles
./install_tentacle.ps1 -octopusServerUrl $octopusServerUrl -registerInEnvironments $registerInEnvironments -registerInRoles $registerInRoles
DEPLOY TENTACLE #>

Set-Location "C:\Startup\scripts"

Write-Output "*"
Get-Script -script "download_tentacle.ps1"
Write-Output "Executing ./download_tentacle.ps1"
./download_tentacle.ps1

Write-Output "VM_UserData startup script completed..."
</powershell>



