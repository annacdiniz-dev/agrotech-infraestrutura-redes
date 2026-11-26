<#
.SYNOPSIS
  AgroTech - para e remove todos os containers e a rede agrotech-lan.
  Use -Limpar para remover tambem as imagens construidas.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\docker\scripts\derrubar.ps1
#>
param([switch]$Limpar)

Set-Location (Join-Path $PSScriptRoot '..')
if ($Limpar) {
    docker compose --profile test down --rmi local
} else {
    docker compose --profile test down
}
