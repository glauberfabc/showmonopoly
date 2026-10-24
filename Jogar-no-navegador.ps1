param([int]$Port = 8765)
$ErrorActionPreference = 'Stop'
$potionUrl = "http://127.0.0.1:$Port/"
$potionResponse = $null
try { $potionResponse = Invoke-WebRequest -Uri $potionUrl -TimeoutSec 2 -UseBasicParsing } catch { }
if ($potionResponse) {
    if ($potionResponse.Content -notmatch '<title>(Potion Master|Show Monopoly)') {
        throw "A porta $Port está ocupada por outro serviço. Execute com -Port 8766."
    }
    Start-Process $potionUrl
    exit
}
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'web/build/index.html'))) {
    throw 'Exporte o preset Web do projeto Godot antes de iniciar.'
}
$potionPython = Join-Path $env:LOCALAPPDATA 'Programs/Python/Python313/python.exe'
if (-not (Test-Path -LiteralPath $potionPython)) {
    $potionPython = (Get-Command python -ErrorAction Stop).Source
}
$potionServer = Start-Process -FilePath $potionPython `
    -ArgumentList '-u','tools/serve_web.py','--port',$Port `
    -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput (Join-Path $PSScriptRoot 'web/server-output.log') `
    -RedirectStandardError (Join-Path $PSScriptRoot 'web/server-error.log')
$potionServer.Id | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'web/server.pid')
for ($potionAttempt = 0; $potionAttempt -lt 20; $potionAttempt++) {
    try {
        $potionResponse = Invoke-WebRequest -Uri $potionUrl -TimeoutSec 2 -UseBasicParsing
        if ($potionResponse.StatusCode -eq 200) { break }
    } catch { Start-Sleep -Milliseconds 200 }
}
if (-not $potionResponse) { throw 'O servidor não iniciou. Consulte web/server-error.log.' }
Start-Process $potionUrl
