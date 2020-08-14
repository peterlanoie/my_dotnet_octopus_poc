<powershell>
$ErrorActionPreference = "stop"

$startupDir = "C:\Startup"
if ((test-path $startupDir) -ne $true) {
  New-Item -ItemType "Directory" -Path $startupDir
}

Set-Location $startupDir

# If for whatever reason this doesn't work, check this file:
$log = ".\StartupLog.txt"
Write-Output " Creating log file at $log"
Start-Transcript -path $log -append

Function Get-Script{
  param (
    [Parameter(Mandatory=$true)][string]$script,
    [string]$owner = "dlmconsultants",
    [string]$repo = "my_dotnet_octopus_poc",
    [string]$branch = "main",
    [string]$path = "Infrastructure/UserDataDownloads",
    [string]$outFile = ".\$repo\$script"
  )
  if ((test-path $repo) -ne $true) {
    Write-Output "  Creating directory $startupDir\$repo"
    New-Item -ItemType "Directory" -Path $repo
  }
  $uri = "https://raw.githubusercontent.com/$owner/$repo/$branch/$path/$script"
  Write-Output "Downloading $script"
  Write-Output "  from: $uri"
  Write-Output "  to: $outFile"
  Invoke-WebRequest -Uri $uri -OutFile $outFile -Verbose
}

Write-Output "*"
Get-Script -script "setup_users.ps1"
Write-Output "Executing ./octopus-demobox-userdata-helper-scripts/setup_users.ps1"
./octopus-demobox-userdata-helper-scripts/setup_users.ps1

Write-Output "*"
Get-Script -script "setup_dotnet_core.ps1"
Write-Output "Executing ./octopus-demobox-userdata-helper-scripts/setup_dotnet_core.ps1"
./octopus-demobox-userdata-helper-scripts/setup_dotnet_core.ps1

Write-Output "*"
Get-Script -script "setup_iis.ps1"
Write-Output "Executing ./octopus-demobox-userdata-helper-scripts/setup_iis.ps1"
./octopus-demobox-userdata-helper-scripts/setup_iis.ps1

$octopusServerUrl = "__OCTOPUSURL__"
$registerInEnvironments = "__ENV__"

Write-Output "*"
Get-Script -script "install_tentacle.ps1"
Write-Output "Executing ./octopus-demobox-userdata-helper-scripts/install_tentacle.ps1 -octopusServerUrl $octopusServerUrl -registerInEnvironments $registerInEnvironments"
./octopus-demobox-userdata-helper-scripts/install_tentacle.ps1 -octopusServerUrl $octopusServerUrl -registerInEnvironments $registerInEnvironments
</powershell>
