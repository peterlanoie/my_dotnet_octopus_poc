$ErrorActionPreference = "Stop"  

# Check to see if holding file exists - implying that another process is already installing AWS Tools
$holdingFile = "$PSScriptRoot/holdingfile.txt"
$warningTime = 90 # seconds
$warningGiven = $false
$timeoutTime = 120 # seconds
if (test-path $holdingFile){
    $holdingFileText = Get-Content -Path $holdingFile -Raw
    Write-Output "    $holdingFileText"
    $AwsBeingInstalled = $true
    $stopwatch =  [system.diagnostics.stopwatch]::StartNew()
    while ($AwsBeingInstalled){
        Start-Sleep -s 5
        $time = [Math]::Floor([decimal]($stopwatch.Elapsed.TotalSeconds))
        if (-not (test-path $holdingFile)){
            $AwsBeingInstalled = $false
            Write-Output "   Looks like the AWS Tools install should be finished now."
            Write-Output "   Verifying that AWS Tools is installed correctly..."
        }
        if ($AwsBeingInstalled){
            Write-Output "      $time seconds: AWS Tools still being installed..."
        }
        if (($time -ge $warningTime) -and (-not $warningGiven)){
            Write-Warning "Installing AWS Tools normally only takes about 70 seconds."
            $warningGiven = $true
        }
        if ($time -ge $timeoutTime){
            Write-Error "Timed out at $time seconds."
        }
    }
}

# Create holding file to stop any other runbooks from installing AWS Tools at the same time
$RunbookRunId = "[RunbookRunId unknown]"
try {
    $RunbookRunId = $OctopusParameters["Octopus.RunbookRun.Id"]
}
catch {
    Write-Warning "Failed to detect Octopus.RunbookRun.Id from Octopus system variables."
}
$startTime = Get-Date
$holdingFileText = "Runbook $RunbookRunId installing AWS tools at: $startTime"
$holdingFileText | out-file $holdingFile

# Installing AWS Tools
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
    Install-Module AWS.Tools.IdentityManagement -Force
}

Write-Output "    AWS Tools is set up and ready to use."

# Delete holding file
Remove-Item $holdingFile