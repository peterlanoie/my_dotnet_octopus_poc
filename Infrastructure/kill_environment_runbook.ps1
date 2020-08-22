param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()]$awsAccessKey,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()]$awsSecretKey,
    $defaulAwsRegion = "eu-west-1" # Other carbon neutral regions are listed here: https://aws.amazon.com/about-aws/sustainability/
)

$ErrorActionPreference = "Stop"  

Write-Output "  Execution root dir: $PSScriptRoot"
Write-Output "*"

# Install AWS tools
Write-Output "Executing .\helper_scripts\install_AWS_tools.ps1..."
Write-Output "  (No parameters)"
& $PSScriptRoot\helper_scripts\install_AWS_tools.ps1
Write-Output "*"

# Configure your default profile
Write-Output "Executing .\helper_scripts\configure_default_aws_profile.ps1..."
Write-Output "  Parameters: -AwsAccessKey $awsAccessKey -AwsSecretKey *** -DefaulAwsRegion $defaulAwsRegion"
& $PSScriptRoot\helper_scripts\configure_default_aws_profile.ps1 -AwsAccessKey $awsAccessKey -AwsSecretKey $awsSecretKey -DefaulAwsRegion $defaulAwsRegion
Write-Output "*"

# Creates the VMs
Write-Output "Executing .\helper_scripts\kill_infra.ps1..."
Write-Output "  (No parameters)"
& $PSScriptRoot\helper_scripts\kill_infra.ps1 
Write-Output "*"
