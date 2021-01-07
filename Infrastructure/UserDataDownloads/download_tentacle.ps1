function Download-File 
{
  param (
    [string]$url,
    [string]$saveAs
  )
 
  Write-Output "    Downloading $url to $saveAs"
  $downloader = new-object System.Net.WebClient
  $downloader.DownloadFile($url, $saveAs)
}

Write-Output "    Downloading latest Octopus Tentacle MSI..."

$tentacleDownloadPath = "http://octopusdeploy.com/downloads/latest/OctopusTentacle64"
$tentaclePath = "C:\Startup.\Tentacle.msi"
if ((test-path $tentaclePath) -ne $true) {
  Download-File $tentacleDownloadPath $tentaclePath
}