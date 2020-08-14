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

# Installing ASP.NET Core 2.2 Runtime (v2.2.8) - Windows Hosting Bundle Installer so that we can deploy ,.NET Core v2.2 websites

$dotnetUrl = "https://download.visualstudio.microsoft.com/download/pr/ba001109-03c6-45ef-832c-c4dbfdb36e00/e3413f9e47e13f1e4b1b9cf2998bc613/dotnet-hosting-2.2.8-win.exe"
$dotnetHostingBundleInstaller = "$startupDir/dotnet-hosting-2.2.8-win.exe"

if ((test-path $dotnetHostingBundleInstaller) -ne $true) {
    Download-File -url $dotnetUrl -SaveAs $dotnetHostingBundleInstaller 
}
else {
    Write-Output "  dotnet core hosting bundle already downloaded to $dotnetHostingBundleInstaller"
}

Write-Output "  Installing ASP.NET Core 2.2 Runtime (v2.2.8) - Windows Hosting Bundle Installer."
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