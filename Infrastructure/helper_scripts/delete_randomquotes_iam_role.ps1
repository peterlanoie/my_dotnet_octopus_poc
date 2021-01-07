$ErrorActionPreference = "Stop"

# Verifying whether role exists
$roleExists = $true
try {
    Get-IAMRole SecretsManager | out-null
}
catch {
    Write-Output "      SecretsManager role does not exist."
    $roleExists = $false
}

# If role exists, delete it
if ($roleExists) {
    Write-Output "      Removing policy from SecretsManager role."
    Get-IAMAttachedRolePolicyList -RoleName SecretsManager | Unregister-IAMRolePolicy -RoleName SecretsManager
    
    Write-Output "      Attempting to remove SecretsManager role RendomQuotes profile."
    try {
        Remove-IAMRoleFromInstanceProfile -InstanceProfileName RandomQuotes -RoleName SecretsManager -Force
        Write-Output "      Removed role SecretsManager from profile RandomQuotes"
    }
    catch {
        Write-Output "      Role SecretsManager was not added to profile RandomQuotes"
    }
    
    Write-Output "      Removing SecretsManager role."
    Remove-IAMRole -RoleName SecretsManager -Force    
}

# If RandomQuotes profile exists, delete it.
try {
    Remove-IAMInstanceProfile -InstanceProfileName RandomQuotes -Force
    Write-Output "      Removed profile RandomQuotes."
}
catch {
    Write-Output "      Profile RandomQuotes does not exist."
}