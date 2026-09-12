param([ValidateSet('Install', 'Uninstall', 'Check')][string]$Mode = 'Check')
$ErrorActionPreference = 'Stop'
function Get-RunningExcel {
    foreach ($candidate in @(Get-Process -Name EXCEL -ErrorAction SilentlyContinue)) {
        try {
            $candidate.Refresh()
            # A terminated process can remain enumerable while a handle to it is held.
            # It cannot run add-in code and must not block installation.
            if ($candidate.HasExited) { continue }
        } catch {
            # Unknown/access-denied status is conservatively treated as running.
        }
        $candidate
    }
}
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
    $excelProcesses = @(Get-RunningExcel)
    if ($excelProcesses.Count -gt 0) {
        Write-Host ''
        Write-Host 'Excel processes are still running (including background instances):' -ForegroundColor Yellow
        foreach ($process in $excelProcesses) {
            $state = 'window status unavailable'
            $started = 'unknown'
            try {
                $process.Refresh()
                if ($process.HasExited) { continue }
                $state = if ($process.MainWindowHandle -eq [IntPtr]::Zero) { 'BACKGROUND / no main window' } else { 'OPEN WINDOW' }
                $started = $process.StartTime.ToString('yyyy-MM-dd HH:mm:ss')
            } catch { }
            Write-Host ('  PID {0} | {1} | started {2}' -f $process.Id, $state, $started)
        }
        Write-Host 'Closing all windows does not always exit Excel: automation or an older add-in can keep it alive.'
        Write-Host 'Save any work. In Task Manager > Details, check the listed EXCEL.EXE PIDs.'
        Write-Host 'End only instances you know are safe to stop, or save your work and restart Windows.'
        Write-Host 'Force-ending a process may lose unsaved data. This script does not terminate processes.'
        if ($Mode -eq 'Check') {
            Write-Host 'Check completed; installation is blocked until Excel processes exit.' -ForegroundColor Yellow
            exit 2
        }
        # Refresh before blocking, in case Excel exited while the status was displayed.
        if (@(Get-RunningExcel).Count -gt 0) {
            throw 'Excel is still running. See the PIDs and background/window status above, then retry.'
        }
    }
    if ($Mode -eq 'Check') { exit 0 }
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
