## Template VirtualEngine.Build ChocolateyInstall.ps1 file for EXE/MSI installations

$citrixWorkspaceAppVersion = '1911'

$webClient = New-Object -TypeName 'System.Net.WebClient'
$webClient.UseDefaultCredentials = $true
$webClient.Proxy = [System.Net.WebRequest]::GetSystemWebProxy()

<# Citrix change the download URL after a new version is released. Here we grab the latest download link from the RSS feed. #>
Write-Host "Resolving Citrix Workspace app $citrixWorkspaceAppVersion download link.."
$rssFeedUri = 'https://www.citrix.com/content/citrix/en_us/downloads/workspace-app.rss'
$rssFeedWebResponse = $webClient.DownloadString($rssFeedUri)
$feed = [System.Xml.XmlDocument] $rssFeedWebResponse
$releaseUri = $feed.rss.channel.item |
                Where-Object { $_.Title -eq "New - Citrix Workspace app $citrixWorkspaceAppVersion for Windows" } |
                    Select-Object -ExpandProperty link

$htmlAgilityPackPath = '{0}\HtmlAgilityPack.dll' -f (Split-Path -Path $MyInvocation.MyCommand.Path)
$null = [System.Reflection.Assembly]::LoadFrom($htmlAgilityPackPath)

<# Citrix sign the download link via Javascript so we have to parse the page to get the signed download Uri. #>
Write-Host "Retrieving Citrix Workspace app $citrixWorkspaceAppVersion download token..."
<# Citrix reject the request with "The remote server returned an error: (403) Forbidden" when no user-agent is specified #>
$webClient.Headers.Add('user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36 Edge/18.18363')
$releaseUriWebResponse = $webClient.DownloadString($releaseUri)
$htmlDocument = New-Object -TypeName 'HtmlAgilityPack.HtmlDocument'
$htmlDocument.LoadHtml($releaseUriWebResponse)
$relativeUri = $htmlDocument.DocumentNode.SelectNodes('//a') |
    ForEach-Object { $_.Attributes } |
        Where-Object { $_.Value -match 'CitrixWorkspaceApp.exe' } |
            Select-Object -ExpandProperty Value
$downloadUri = 'https:{0}' -f $relativeUri

$installChocolateyPackageParams = @{
    PackageName    = "Citrix-Workspace";
    FileType       = "EXE";
    SilentArgs     = "/noreboot /silent";
    Url            = "$downloadUri";
    ValidExitCodes = @(0,3010);
    Checksum       = "33E61D561B9BEB3F5FC3D2BDB71C5BF9D166135F596FA16A8AA01730FECC236E";
    ChecksumType   = "sha256";
}
Install-ChocolateyPackage @installChocolateyPackageParams;

<#! POST-INSTALL-TASKS !#>
