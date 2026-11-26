<#
.SYNOPSIS
  AgroTech - sobe os servicos (DHCP, DNS, Web, FTP).
  Use -ComCliente para subir tambem o cliente de teste.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\docker\scripts\subir.ps1 -ComCliente
#>
param([switch]$ComCliente)

Set-Location (Join-Path $PSScriptRoot '..')
if ($ComCliente) {
    docker compose --profile test up -d --build
} else {
    docker compose up -d --build
}
docker compose --profile test ps
Write-Host ''
Write-Host 'Intranet: http://localhost:8080' -ForegroundColor Cyan
