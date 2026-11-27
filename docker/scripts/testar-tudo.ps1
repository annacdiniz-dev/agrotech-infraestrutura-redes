<#
.SYNOPSIS
  AgroTech - roda a sequencia completa de testes dos servicos Docker
  (DHCP, DNS, Web e FTP) e grava as saidas na pasta evidencias/.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\docker\scripts\testar-tudo.ps1
#>

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Raiz   = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Docker = Join-Path $Raiz 'docker'
$Evid   = Join-Path $Raiz 'evidencias'
New-Item -ItemType Directory -Force $Evid | Out-Null
Set-Location $Docker

$Resultados = [ordered]@{}

function Titulo($texto) {
    Write-Host ''
    Write-Host ('=' * 70) -ForegroundColor DarkGreen
    Write-Host "  $texto" -ForegroundColor Green
    Write-Host ('=' * 70) -ForegroundColor DarkGreen
}

# Executa um comando dentro do cliente de teste e devolve o texto da saida,
# ja com a linha do comando no inicio (formato de evidencia).
function NoCliente($comando) {
    $saida = docker compose exec -T cliente sh -c "$comando 2>&1" | Out-String
    return "pc-teste:~# $comando`r`n$saida"
}

function Salvar($arquivo, $conteudo) {
    $cab = "AgroTech - evidencia gerada por docker/scripts/testar-tudo.ps1`r`nData: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')`r`n`r`n"
    ($cab + $conteudo) | Out-File -FilePath (Join-Path $Evid $arquivo) -Encoding utf8
    Write-Host $conteudo
    Write-Host "[evidencia salva em evidencias/$arquivo]" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------
Titulo 'Passo 0 - Verificando o Docker'
docker info --format '{{.ServerVersion}}' *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'O Docker nao esta respondendo. Abra o Docker Desktop, espere ficar "Running" e rode de novo.' -ForegroundColor Red
    exit 1
}
Write-Host 'Docker OK.'

# ---------------------------------------------------------------------
Titulo 'Passo 1 - Subindo os servicos (DHCP, DNS, Web, FTP)'
# Sem o "atestado de procedencia" do BuildKit, a imagem reconstruida do cache fica identica
# a anterior; com ele, cada build gera uma imagem nova e os containers em execucao ficariam
# apontando para a versao antiga (aparece so o ID, sem nome, no Docker Desktop).
$env:BUILDX_NO_DEFAULT_ATTESTATIONS = '1'
docker compose --profile test build
docker compose up -d
# Recria o cliente para o teste de DHCP comecar "do zero" (com o IP inicial do Docker)
docker compose --profile test up -d --force-recreate --no-deps cliente
Start-Sleep -Seconds 3

$ps = "PS> docker compose --profile test ps`r`n" + (docker compose --profile test ps | Out-String)
$ps += "`r`nPS> docker network inspect agrotech-lan (resumo)`r`n"
$ps += (docker network inspect agrotech-lan --format 'Rede: {{.Name}} | Driver: {{.Driver}} | Sub-rede: {{range .IPAM.Config}}{{.Subnet}} | Gateway: {{.Gateway}} | ip_range: {{.IPRange}}{{end}}' | Out-String)
$ps += (docker network inspect agrotech-lan --format '{{range .Containers}}{{.Name}}  {{.IPv4Address}}{{println}}{{end}}' | Out-String)
Salvar 'docker-ps.txt' $ps

# ---------------------------------------------------------------------
Titulo 'Teste 1 - DHCP: o cliente pede um IP ao servidor 192.168.30.10'
$inicio = (Get-Date).ToUniversalTime().AddSeconds(-2).ToString('yyyy-MM-ddTHH:mm:ssZ')
$t = ''
$t += NoCliente 'ip -4 addr show eth0'
$t += "`r`n(acima: IP inicial dado pelo Docker, faixa 192.168.30.0/28)`r`n`r`n"
$t += NoCliente 'udhcpc -i eth0 -n -q -f'
$t += "`r`n"
$t += NoCliente 'ip -4 addr show eth0'
$t += NoCliente 'ip route'
$t += NoCliente 'cat /etc/resolv.conf'
Start-Sleep -Seconds 1
$logs = docker compose logs --no-color --since $inicio dhcp | Out-String
$dora = ($logs -split "`n" | Where-Object { $_ -match 'DHCP(DISCOVER|OFFER|REQUEST|ACK)' }) -join "`n"
$t += "`r`n----- Processo DORA no log do servidor (docker compose logs dhcp) -----`r`n$dora`r`n"
$t += "`r`n----- Log completo do dnsmasq (log-dhcp) neste teste -----`r`n$logs"
Salvar 'teste-dhcp.txt' $t
$Resultados['DHCP (IP do pool .100-.200)'] = ($t -match 'lease of 192\.168\.30\.(1\d\d|200) obtained from 192\.168\.30\.10') -and ($dora -match 'DHCPACK')

# ---------------------------------------------------------------------
Titulo 'Teste 2 - DNS: resolucao de nomes no servidor 192.168.30.11'
$t = ''
$t += NoCliente 'nslookup intranet.agrotech.local 192.168.30.11'
$t += NoCliente 'nslookup erp.agrotech.local'
$t += NoCliente 'nslookup ftp.agrotech.local'
$t += NoCliente 'nslookup dhcp.agrotech.local'
$t += NoCliente 'nslookup fw.agrotech.local'
$t += NoCliente 'nslookup 192.168.30.12'
$t += NoCliente 'nslookup inexistente.agrotech.local'
$t += NoCliente 'nslookup www.google.com'
$t += NoCliente 'dig +short intranet.agrotech.local @192.168.30.11'
$t += "`r`n----- Consultas registradas pelo servidor (docker compose logs dns) -----`r`n"
$t += (docker compose logs --no-color --tail 30 dns | Out-String)
Salvar 'teste-dns.txt' $t
$Resultados['DNS (intranet -> 192.168.30.12)'] = ($t -match 'Name:\s+intranet\.agrotech\.local\s+Address: 192\.168\.30\.12') -and ($t -match 'canonical name = intranet\.agrotech\.local')

# ---------------------------------------------------------------------
Titulo 'Teste 3 - Web: intranet servida pelo nginx em 192.168.30.12'
$t = ''
$t += NoCliente 'curl -sI http://192.168.30.12'
$t += NoCliente 'curl -s http://intranet.agrotech.local/saude'
$t += NoCliente "curl -s http://intranet.agrotech.local | grep -o '<title>.*</title>'"
$t += NoCliente "curl -s http://erp.agrotech.local | grep -c AgroTech"
$t += "`r`n----- Acesso pelo Windows (porta publicada 8080) -----`r`n"
try {
    $r = Invoke-WebRequest -Uri 'http://localhost:8080' -UseBasicParsing -TimeoutSec 10
    $t += "PS> Invoke-WebRequest http://localhost:8080`r`nStatusCode: $($r.StatusCode)  Tamanho: $($r.RawContentLength) bytes  X-Servidor: $($r.Headers['X-Servidor'])`r`n"
    $hostOk = ($r.StatusCode -eq 200)
} catch {
    $t += "Falha ao acessar http://localhost:8080 : $($_.Exception.Message)`r`n"
    $hostOk = $false
}
$t += "`r`n----- Log de acesso do nginx -----`r`n"
$t += (docker compose logs --no-color --tail 8 web | Out-String)
Salvar 'teste-web.txt' $t
$Resultados['Web (HTTP 200 no container e no host)'] = ($t -match 'HTTP/1\.1 200 OK') -and $hostOk

# ---------------------------------------------------------------------
Titulo 'Teste 4 (bonus) - FTP em 192.168.30.13'
$t = ''
$t += NoCliente 'curl -s --list-only ftp://agrotech:agrotech123@ftp.agrotech.local/arquivos/'
$t += NoCliente 'curl -s ftp://agrotech:agrotech123@ftp.agrotech.local/arquivos/LEIA-ME.txt'
$t += NoCliente 'echo Relatorio enviado pelo pc-teste > /tmp/relatorio.txt && curl -sS -T /tmp/relatorio.txt ftp://agrotech:agrotech123@ftp.agrotech.local/arquivos/ && echo upload-ok'
$t += NoCliente 'curl -s --list-only ftp://agrotech:agrotech123@ftp.agrotech.local/arquivos/'
$t += NoCliente 'curl -sS ftp://agrotech:senhaerrada@ftp.agrotech.local/ || echo login-recusado'
$t += "`r`n----- Log do vsftpd -----`r`n"
$t += (docker compose logs --no-color --tail 15 ftp | Out-String)
Salvar 'teste-ftp.txt' $t
$Resultados['FTP (listar, baixar, enviar, negar senha errada)'] = ($t -match 'upload-ok') -and ($t -match 'relatorio\.txt') -and ($t -match '530')

# ---------------------------------------------------------------------
Titulo 'Resumo'
$resumo = ''
foreach ($k in $Resultados.Keys) {
    $st = if ($Resultados[$k]) { 'PASSOU' } else { 'FALHOU' }
    $cor = if ($Resultados[$k]) { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1}" -f $st, $k) -ForegroundColor $cor
    $resumo += ("[{0}] {1}`r`n" -f $st, $k)
}
$resumo | Out-File -FilePath (Join-Path $Evid 'resumo-testes.txt') -Encoding utf8
Write-Host ''
Write-Host 'Intranet no navegador: http://localhost:8080' -ForegroundColor Cyan
if ($Resultados.Values -contains $false) { exit 1 }
