$ErrorActionPreference = 'Stop'
$source = Join-Path (Split-Path $PSScriptRoot -Parent) 'packaging\Manage.ps1'
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($source, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'Installer syntax error.' }
$definition = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-RunningExcel' }, $true)
. ([scriptblock]::Create($definition.Extent.Text))
function Get-Process { param($Name, $ErrorAction) $script:FakeProcesses }
function New-FakeProcess([bool]$exited) {
    $item = [pscustomobject]@{ HasExited = $exited }
    $item | Add-Member -MemberType ScriptMethod -Name Refresh -Value { }
    $item
}
$script:FakeProcesses = @((New-FakeProcess $true), (New-FakeProcess $true))
if (@(Get-RunningExcel).Count -ne 0) { throw 'Exited entries still block installation.' }
$live = New-FakeProcess $false
$script:FakeProcesses = @((New-FakeProcess $true), $live)
$result = @(Get-RunningExcel)
if ($result.Count -ne 1 -or -not [object]::ReferenceEquals($result[0], $live)) { throw 'Live process filtering failed.' }
$unknown = [pscustomobject]@{}
$unknown | Add-Member -MemberType ScriptMethod -Name Refresh -Value { throw 'Access denied' }
$script:FakeProcesses = @($unknown)
if (@(Get-RunningExcel).Count -ne 1) { throw 'Unknown state should conservatively block.' }
$script:FakeProcesses = @()
if (@(Get-RunningExcel).Count -ne 0) { throw 'Empty process list failed.' }
Write-Output 'PASS: exited-only, mixed live/exited, unknown status, empty process list.'
