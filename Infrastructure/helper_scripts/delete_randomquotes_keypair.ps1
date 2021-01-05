param(
    $keyPairName = "RandomQuotes"
)

$ErrorActionPreference = "Stop"  

# Helper function to see if keypair exists
function Test-KeyPair {
    param (
        $name
    )

    try {
        Get-EC2KeyPair -KeyName $name | out-null
        return $true
    }
    catch {
        return $false
    }
}

# Deleting keypair
$keyPairExistsBefore = Test-KeyPair $keyPairName
if ($keyPairExistsBefore) {
    Write-Output "    Keypair exists in EC2."
    Write-Output "    Deleting keypair: $keyPairName"
    Remove-EC2KeyPair -KeyName $keyPairName -Force
}
else {
    "    $keyPairName keypair does not exist in EC2. No need to delete it."
}

# Verifying keypair deleted
$keyPairExistsAfter = Test-KeyPair $keyPairName
if ($keyPairExistsBefore -and $keyPairExistsAfter) {
    Write-Error "    Failed to delete keypair: $keyPairName"
}
if ($keyPairExistsBefore -and -not $keyPairExistsAfter) {
    Write-Output "    Keypair successfully deleted."
}
