param([ValidateSet('Install', 'Uninstall', 'Check')][string]$Mode = 'Check')
$ErrorActionPreference = 'Stop'
try {
    if (-not [Environment]::Is64BitProcess) { throw 'Run using 64-bit Windows PowerShell.' }
    $manifest = Join-Path $PSScriptRoot 'App\ExcelShiftScroll.vsto'
    if (-not (Test-Path -LiteralPath $manifest)) { throw 'Package incomplete: App\ExcelShiftScroll.vsto is missing.' }
    $candidates = @(
        (Join-Path $env:CommonProgramFiles 'Microsoft Shared\VSTO\10.0\VSTOInstaller.exe'),
        (Join-Path ${env:CommonProgramFiles(x86)} 'Microsoft Shared\VSTO\10.0\VSTOInstaller.exe')
    )
    $installer = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $installer) { throw 'Microsoft Visual Studio 2010 Tools for Office Runtime is required. See README.txt.' }
    $framework = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction SilentlyContinue
    if (-not $framework -or $framework.Release -lt 528040) { throw '.NET Framework 4.8 or newer is required.' }
    $office = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' -ErrorAction SilentlyContinue
    if ($office -and $office.Platform -ne 'x64') { throw 'This package requires 64-bit Office.' }

    # Verify the package before handing it to the official installer, which also
    # validates the signed VSTO manifests and handles the trust dialog normally.
    $index = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'PackageHashes.json') -Raw | ConvertFrom-Json
    foreach ($entry in $index) {
        $path = Join-Path $PSScriptRoot $entry.Path
        if (-not (Test-Path -LiteralPath $path) -or
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $entry.SHA256) {
            throw ('Missing or modified package file: ' + $entry.Path)
        }
    }
    Write-Host 'Package integrity and runtime checks passed.'
    if ($Mode -eq 'Check') { exit 0 }
    if (Get-Process EXCEL -ErrorAction SilentlyContinue) {
        throw 'Save your work and close all Excel windows, then run this command again.'
    }
    $uri = ([Uri]$manifest).AbsoluteUri
    if ($Mode -eq 'Install') {
        Write-Host 'Installing ExcelShiftScroll for the current user. Follow the Office installer dialog.'
        & $installer /Install $uri
    } else {
        Write-Host 'Removing ExcelShiftScroll for the current user.'
        & $installer /Uninstall $uri
    }
    if ($LASTEXITCODE -ne 0) { throw ('VSTO installer returned code ' + $LASTEXITCODE + '. See the installer message and README.txt.') }
    if ($Mode -eq 'Install') {
        Write-Host 'Installation completed. Open Excel normally and use Shift + mouse wheel.'
    } else { Write-Host 'Uninstallation completed.' }
    exit 0
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
