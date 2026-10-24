param(
    [Parameter(Mandatory = $true)][string]$Godot,
    [switch]$Simulate
)
$ErrorActionPreference = 'Stop'
$potionProject = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$potionEngine = (Resolve-Path -LiteralPath $Godot).Path
$env:APPDATA = Join-Path $potionProject '.deploy/test-appdata'
$env:LOCALAPPDATA = Join-Path $potionProject '.deploy/test-localappdata'
New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA | Out-Null
$potionSuites = @('test_board', 'test_touch_vaults', 'test_prizes_vault_limits', 'test_hold_spin')

foreach ($potionSuite in $potionSuites) {
    $potionOut = Join-Path $PSScriptRoot "$potionSuite-output.log"
    $potionErr = Join-Path $PSScriptRoot "$potionSuite-error.log"
    $potionProcess = Start-Process -FilePath $potionEngine -WorkingDirectory $potionProject `
        -ArgumentList '--path', '.', '--no-window', '--audio-driver', 'Dummy', '--script', "tests/$potionSuite.gd" `
        -WindowStyle Hidden -PassThru -RedirectStandardOutput $potionOut -RedirectStandardError $potionErr
    if (-not $potionProcess.WaitForExit(60000)) { $potionProcess.Kill(); throw "Test timed out: $potionSuite" }
    Get-Content -LiteralPath $potionOut
    Get-Content -LiteralPath $potionErr
    if ($potionProcess.ExitCode -ne 0 -or (Select-String -LiteralPath $potionErr -Pattern 'SCRIPT ERROR|SHADER ERROR|FAIL ' -Quiet)) {
        throw "Potion Master: $potionSuite failed."
    }
}
Write-Output 'Potion Master Board & Bonus: verification passed.'
