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

# Installing ASP.NET Core 2.0 Runtime (v2.0.3) - Windows Hosting Bundle Installer so that we can deploy ,.NET Core v2.0 websites

$dotnetUrl = "https://download.microsoft.com/download/5/C/1/5C190037-632B-443D-842D-39085F02E1E8/DotNetCore.2.0.3-WindowsHosting.exe"
$dotnetHostingBundleInstaller = "$startupDir/DotNetCore.2.0.3-WindowsHosting.exe"

if ((test-path $dotnetHostingBundleInstaller) -ne $true) {
    Download-File -url $dotnetUrl -SaveAs $dotnetHostingBundleInstaller 
}
else {
    Write-Output "  dotnet core hosting bundle already downloaded to $dotnetHostingBundleInstaller"
}

Write-Output "  Installing ASP.NET Core 2.0 Runtime (v2.0.3) - Windows Hosting Bundle Installer."
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
