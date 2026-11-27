# Evidências

## Saídas dos testes Docker (geradas automaticamente)

Geradas por [`docker/scripts/testar-tudo.ps1`](../docker/scripts/testar-tudo.ps1); cada execução sobrescreve os arquivos.

| Arquivo | Conteúdo |
|---|---|
| [`docker-ps.txt`](docker-ps.txt) | Containers em execução e IPs na rede `agrotech-lan` |
| [`teste-dhcp.txt`](teste-dhcp.txt) | Cliente recebendo IP + log DORA do servidor |
| [`teste-dns.txt`](teste-dns.txt) | Consultas A, CNAME, PTR, NXDOMAIN e externas |
| [`teste-web.txt`](teste-web.txt) | Acesso HTTP pelo container e pelo Windows |
| [`teste-ftp.txt`](teste-ftp.txt) | Listagem, download, upload e senha recusada |
| [`resumo-testes.txt`](resumo-testes.txt) | PASSOU/FALHOU de cada teste |

## Prints (`prints/`)

| Arquivo | O que mostrar |
|---|---|
| `docker-01-containers.png` | Docker Desktop → **Containers**, projeto `agrotech` aberto com os 5 containers verdes |
| `docker-02-intranet-navegador.png` | Navegador em `http://localhost:8080` |
| `docker-04-logs-dhcp-dora.png` | Docker Desktop → `agrotech-dhcp` → aba **Logs**, com DHCPDISCOVER/OFFER/REQUEST/ACK |
| `pt-01`, `pt-02`, `pt-04`, `pt-05`, `pt-09` | Prints do Packet Tracer: lista em [`packet-tracer/README.md`](../packet-tracer/README.md#10-tirar-os-prints-e-salvar-o-arquivo) |

O resumo `[PASSOU]` do script não tem print: ele já está em texto em [`resumo-testes.txt`](resumo-testes.txt). Os números dos arquivos seguem os nomes usados no relatório Word e por isso pulam alguns números.
