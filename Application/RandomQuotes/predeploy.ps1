Write-output "Starting pre-deploy script..."

$site = Get-Website -Name "Default Web Site"

if ($site -ne $NULL){
    Write-Output "  Default Website detected running on port 80."
    Write-Output "  Removing Default Website to make space for new Website."
    Remove-WebSite -Name "Default Web Site"
}
else {
    Write-output "  Default Website not detected. No need to remove it."
}

Write-output "Pre-deploy script completed."
