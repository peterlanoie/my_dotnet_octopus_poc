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
    Write-Output "      Removing SecretsManager role."
    Remove-IAMRole -RoleName SecretsManager -Force    
}
