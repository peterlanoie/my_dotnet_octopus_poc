param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()]$awsAccessKey,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()]$awsSecretKey,
    $defaulAwsRegion = "eu-west-1", # Other carbon neutral regions are listed here: https://aws.amazon.com/about-aws/sustainability/
    $keyPairName = "RandomQuotes",
    $keyPairDir = "C:\keypairs",
    $securityGroupName = "RandomQuotes"
)

$ErrorActionPreference = "Stop"  

Write-Output "Execution root dir: $PSScriptRoot"

# Install AWS tools
Write-Output "Executing .\helper_scripts\install_AWS_tools.ps1..."
Write-Output "  (No parameters)"
& $PSScriptRoot\helper_scripts\install_AWS_tools.ps1

# Configure your default profile
Write-Output "Executing .\helper_scripts\configure_default_aws_profile.ps1..."
Write-Output "  Parameters: -AwsAccessKey [MASKED] -AwsSecretKey [MASKED] -DefaulAwsRegion $defaulAwsRegion"
& $PSScriptRoot\helper_scripts\configure_default_aws_profile.ps1 -AwsAccessKey $awsAccessKey -AwsSecretKey $awsSecretKey -DefaulAwsRegion $defaulAwsRegion

# Creates a new keypair
Write-Output "Executing .\helper_scripts\create-keypair.ps1..."
Write-Output "  Parameters: -keyPairName $keyPairName -keyPairDir $keyPairDir"
& $PSScriptRoot\helper_scripts\create_keypair.ps1 -keyPairName $keyPairName -keyPairDir $keyPairDir

# Creates a security group in AWS to allow RDP sessions on all your demo VMs
Write-Output "Executing .\helper_scripts\create_security_group.ps1..."
Write-Output "  Parameters: -securityGroupName $securityGroupName"
& $PSScriptRoot\helper_scripts\create_security_group.ps1 -securityGroupName $securityGroupName

# Creates a SecretsManager role in AWS which has access to AWS Secrets Manager
Write-Output "Executing .\helper_scripts\create_AWS_role.ps1..."
Write-Output "  (No parameters)"
& $PSScriptRoot\helper_scripts\create_AWS_role.ps1

# Creates a RandomQuotes profile containing the SecretsManager role for all VMs
# This allows the VMs to access secrets manager, which allows us to avoid hardcoding passwords into sourcecode/the userdata file
Write-Output "Executing .\helper_scripts\add_role_to_profile.ps1..."
Write-Output "  (No parameters)"
& $PSScriptRoot\helper_scripts\add_role_to_profile.ps1