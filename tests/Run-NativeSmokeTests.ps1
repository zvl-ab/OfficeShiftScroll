$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$installation = & $vswhere -latest -products '*' -property installationPath
$compiler = Join-Path $installation 'MSBuild\Current\Bin\Roslyn\csc.exe'
$output = Join-Path $projectRoot 'obj\NativeSmokeTests.exe'
& $compiler /nologo /target:exe /platform:x64 /langversion:latest "/out:$output" `
    (Join-Path $projectRoot 'Win32.cs') (Join-Path $projectRoot 'MouseHook.cs') `
    (Join-Path $projectRoot 'HorizontalScrollHandler.cs') (Join-Path $projectRoot 'DiagnosticLog.cs') `
    (Join-Path $PSScriptRoot 'NativeSmokeTests.cs')
if ($LASTEXITCODE -ne 0) { throw 'Smoke test compilation failed.' }
& $output
if ($LASTEXITCODE -ne 0) { throw 'Native smoke tests failed.' }
