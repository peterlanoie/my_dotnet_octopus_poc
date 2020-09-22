function Download-File 
{
  param (
    [string]$url,
    [string]$saveAs
  )
 
  Write-Host "  Downloading $url to $saveAs"
  $downloader = new-object System.Net.WebClient
  $downloader.DownloadFile($url, $saveAs)
}

# Installing ASP.NET Core Runtime - Windows Hosting Bundle Installer so that we can deploy ,.NET Core websites
$dotnetversion = "3.1.8"
$dotnetUrl = "https://download.visualstudio.microsoft.com/download/pr/854cbd11-4b96-4a44-9664-b95991c0c4f7/8ec4944a5bd770faba2f769e647b1e6e/dotnet-hosting-3.1.8-win.exe"
$dotnetHostingBundleInstaller = "$startupDir/dotnet-hosting-$dotnetversion-win.exe"

if ((test-path $dotnetHostingBundleInstaller) -ne $true) {
    Download-File -url $dotnetUrl -SaveAs $dotnetHostingBundleInstaller 
}
else {
    Write-Output "  dotnet core hosting bundle already downloaded to $dotnetHostingBundleInstaller"
}

Write-Output "  Installing ASP.NET Core Runtime (v$dotnetversion) - Windows Hosting Bundle Installer."
$args = New-Object -TypeName System.Collections.Generic.List[System.String]
$args.Add("/quiet")
$args.Add("/install")
$args.Add("/norestart")
$Output = Start-Process -FilePath $dotnetHostingBundleInstaller -ArgumentList $args -NoNewWindow -Wait -PassThru

Write-Output "  Re-starting IIS."
If($Output.Exitcode -Eq 0)
{
    net stop was /y
    net start w3svc
}
else {
    Write-HError "`t`t Something went wrong with the installation. Errorlevel: ${Output.ExitCode}"
    Exit 1
}
