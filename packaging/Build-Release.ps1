param([string]$Version = '1.0.1')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Use a three-part version, for example 1.0.1.' }
$assembly = Get-Content -LiteralPath (Join-Path $root 'Properties\AssemblyInfo.cs') -Raw
if (-not $assembly.Contains('AssemblyVersion("' + $Version + '.0")')) { throw 'Version must match Properties/AssemblyInfo.cs.' }
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vs = & $vswhere -latest -products '*' -property installationPath
if (-not $vs) { throw 'Visual Studio with Office/VSTO tools is required.' }
$msbuild = Join-Path $vs 'MSBuild\Current\Bin\MSBuild.exe'
$name = "OfficeShiftScroll-$Version-x64"
$artifactRoot = Join-Path $root 'artifacts'
$package = Join-Path $artifactRoot $name
$zip = Join-Path $artifactRoot "$name.zip"
if ((Test-Path -LiteralPath $package) -or (Test-Path -LiteralPath $zip)) {
    throw 'Release output already exists. Archive or remove that specific version before rebuilding.'
}
$app = (Join-Path $package 'App') + '\'
& $msbuild (Join-Path $root 'ExcelShiftScroll.csproj') /t:Publish /p:Configuration=Release /p:Platform=x64 "/p:PublishDir=$app" "/p:PublishUrl=$app" /p:BootstrapperEnabled=false /p:UpdateEnabled=false "/p:ApplicationVersion=$Version.0" /v:minimal /nologo
if ($LASTEXITCODE -ne 0) { throw 'Signed VSTO publish failed.' }
foreach ($file in @('Manage.ps1','Install.cmd','Uninstall.cmd','Check.cmd','README.txt')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination (Join-Path $package $file)
}
Copy-Item -LiteralPath (Join-Path $root 'CHANGELOG.md') -Destination (Join-Path $package 'CHANGELOG.md')
Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination (Join-Path $package 'LICENSE')
$hashes = @(Get-ChildItem -LiteralPath $app -Recurse -File | Sort-Object FullName | ForEach-Object {
    [pscustomobject]@{ Path=$_.FullName.Substring($package.Length + 1); SHA256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
})
ConvertTo-Json -InputObject $hashes | Set-Content -LiteralPath (Join-Path $package 'PackageHashes.json') -Encoding utf8
if (Get-ChildItem -LiteralPath $package -Recurse -File | Where-Object { $_.Extension -in @('.pfx','.p12','.key','.pem') }) {
    throw 'Private key file found in release output.'
}
Compress-Archive -LiteralPath $package -DestinationPath $zip
$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath (Join-Path $artifactRoot "$name.zip.sha256") -Value "$hash  $name.zip" -Encoding ascii
Write-Output "Release package: $zip"
