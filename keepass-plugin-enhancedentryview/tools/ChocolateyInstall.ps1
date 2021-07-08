# powershell v2 compatibility
$psVer = $PSVersionTable.PSVersion.Major
if ($psver -ge 3) {
    function Get-ChildItemDir { Get-ChildItem -Directory $args }
} else {
    function Get-ChildItemDir { Get-ChildItem $args }
}

$packageName = $env:ChocolateyPackageName
$keePassDisplayName = 'KeePass Password Safe'

Write-Verbose "Searching $env:ChocolateyBinRoot..."
$installPath = Get-AppInstallLocation "^$keePassDisplayName"

if (!$installPath) {
    Write-Verbose "Searching $env:ChocolateyBinRoot for portable install..."
    $binRoot = Get-BinRoot
    $portPath = Join-Path $binRoot "keepass"
    $installPath = Get-ChildItemDir $portPath* -ErrorAction SilentlyContinue
}
if (!$installPath) {
    throw "$keePassDisplayName not found."
}
Write-Verbose "`t...found: $installPath"

Write-Verbose "Searching for plugin directory..."
$pluginPath = (Get-ChildItemDir $installPath\Plugin*).FullName
if ($pluginPath.Count -eq 0) {
    $pluginPath = Join-Path $installPath "Plugins"
    [System.IO.Directory]::CreateDirectory($pluginPath)
}
Write-Verbose "`t...found."

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$packageArgs = @{
    packageName    = $packageName
    unzipLocation  = $toolsDir
    url            = 'https://sourceforge.net/projects/kpenhentryview/files/v2.4.1/KPEnhancedEntryView-v2.4.1.zip'
    checksum       = '15C6DD3D28384F881E340B8D506A5BF5ADD7FC2D'
    checksumType   = 'SHA1'
}

Install-ChocolateyZipPackage  @packageArgs
    
Write-Verbose "Copy plugin files into Plugins dir"
Copy-Item -Path "$toolsDir\*.plgx" -Destination $pluginPath -Recurse -Force

if ( Get-Process -Name "KeePass" -ErrorAction SilentlyContinue ) {
    Write-Warning "$keePassDisplayName is currently running. Plugin will be available at next restart of KeePass process." 
} else {
    Write-Host "$packageName will be loaded the next time KeePass is started."
    Write-Host "Please note this plugin may require additional configuration. Look for a new entry in KeePass' Tools>Options"
}
