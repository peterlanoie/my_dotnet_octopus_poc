$ErrorActionPreference = "Stop"  

$Installedmodules = Get-InstalledModule

if ($Installedmodules.name -contains "AWS.Tools.Common"){
    Write-Output "    Module AWS.Tools.Common is already installed "
}
else {
    Write-Output "    AWS.Tools.Common is not installed."
    Write-Output "    Installing AWS.Tools.Common..."
    Install-Module AWS.Tools.Common -Force
}

if ($Installedmodules.name -contains "AWS.Tools.EC2"){
    Write-Output "    Module AWS.Tools.EC2 is already installed."
}
else {
    Write-Output "    AWS.Tools.EC2 is not installed."
    Write-Output "    Installing AWS.Tools.EC2..."
    Install-Module AWS.Tools.EC2 -Force
}

if ($Installedmodules.name -contains "AWS.Tools.IdentityManagement"){
    Write-Output "    Module AWS.Tools.IdentityManagement is already installed "
}
else {
    Write-Output "    AWS.Tools.IdentityManagement is not installed."
    Write-Output "    Installing AWS.Tools.IdentityManagement..."
    Install-Module AWS.Tools.Common -Force
}
