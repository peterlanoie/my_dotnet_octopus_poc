param(
    $roleName = "SecretsManager"
)
$ErrorActionPreference = "Stop"  

$policy = "$PSScriptRoot\IAM_SecretsManager_Policy.json"
"Policy is saved at: $policy"


$createRole = $false
try {
    Get-IamRole -RoleName $roleName | out-null
    Write-Output "    Role $roleName already exists."
}
catch {
    Write-Output "    Role $roleName does not exist."
    $createRole = $true
}

if ($createRole) {
    Write-Output "    Creating role $roleName from policy saved at: $policy"
    New-IAMRole -AssumeRolePolicyDocument (Get-Content -raw $policy) -RoleName $roleName
} 
else {
    Write-Output "    Role $roleName already exists."
}
