# Publica o Show Monopoly na VPS (Windows PowerShell). Pede a senha do SSH no terminal; nada fica salvo.
# Uso:  powershell -ExecutionPolicy Bypass -File deploy\publicar-vps.ps1
$HostSsh = "root@2.25.190.121"
$Port = 8099
$Raiz = Split-Path -Parent $PSScriptRoot
$Build = Join-Path $Raiz "web\build"
if (-not (Test-Path (Join-Path $Build "index.pck"))) { throw "web\build não encontrado" }

Write-Host "1/3 preparando servidor..."
ssh $HostSsh "mkdir -p /var/www/showmonopoly && (command -v nginx >/dev/null || (apt-get update -y && apt-get install -y nginx))"

Write-Host "2/3 enviando arquivos..."
scp -r "$Build\*" "${HostSsh}:/var/www/showmonopoly/"

Write-Host "3/3 configurando nginx (porta $Port)..."
$conf = @"
server {
    listen $Port;
    server_name _;
    root /var/www/showmonopoly;
    index index.html;
    types { application/wasm wasm; }
    default_type application/octet-stream;
    gzip on;
    gzip_types application/wasm application/octet-stream application/javascript text/css;
    gzip_min_length 1024;
    location / { try_files `$uri `$uri/ /index.html; add_header Cache-Control "no-cache"; }
}
"@
$conf | ssh $HostSsh "cat > /etc/nginx/conf.d/showmonopoly.conf && nginx -t && systemctl reload nginx && (command -v ufw >/dev/null && ufw allow $Port/tcp || true)"
Write-Host "Pronto: http://2.25.190.121:$Port/"
