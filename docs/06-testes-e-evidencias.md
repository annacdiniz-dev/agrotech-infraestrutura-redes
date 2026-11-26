# 6. Testes e evidências

Este documento lista cada teste realizado, o comando usado, o resultado esperado e onde está a evidência. Há dois ambientes:

- **Docker** (serviços reais em containers): as saídas são geradas automaticamente pelo script [`docker/scripts/testar-tudo.ps1`](../docker/scripts/testar-tudo.ps1) e gravadas em [`evidencias/`](../evidencias/).
- **Cisco Packet Tracer** (simulação da infraestrutura completa): as evidências são prints em [`evidencias/prints/`](../evidencias/prints/). O roteiro de execução está em [`packet-tracer/README.md`](../packet-tracer/README.md#9-executar-os-testes).

## 6.1 Resumo

| # | Ambiente | Teste | Resultado | Evidência |
|---|---|---|---|---|
| D0 | Docker | Containers no ar e rede `agrotech-lan` | **Passou** | [`docker-ps.txt`](../evidencias/docker-ps.txt) |
| D1 | Docker | DHCP: cliente recebe IP do pool, gateway e DNS (DORA completo) | **Passou** | [`teste-dhcp.txt`](../evidencias/teste-dhcp.txt) |
| D2 | Docker | DNS: registros A, CNAME, PTR, NXDOMAIN e encaminhamento externo | **Passou** | [`teste-dns.txt`](../evidencias/teste-dns.txt) |
| D3 | Docker | Web: intranet pelo IP, pelo nome e pelo Windows (porta 8080) | **Passou** | [`teste-web.txt`](../evidencias/teste-web.txt) |
| D4 | Docker | FTP: listar, baixar, enviar e recusar senha errada | **Passou** | [`teste-ftp.txt`](../evidencias/teste-ftp.txt) |
| P1–P18 | Packet Tracer | DHCP com relay, pings intra/inter-VLAN, matriz ↔ filial, DNS, HTTP, FTP, ACL de visitantes | A executar pela equipe | `evidencias/prints/pt-*.png` |

Resumo da última execução do script: [`resumo-testes.txt`](../evidencias/resumo-testes.txt).

---

## 6.2 Testes no Docker

### D0 — Serviços no ar

```powershell
docker compose --profile test ps
docker network inspect agrotech-lan
```

**Esperado:** os 5 containers com status `Up`; rede `agrotech-lan` com sub-rede 192.168.30.0/24, gateway .1, `ip_range` .0/28, e os IPs .10, .11, .12, .13 nos serviços.

**Obtido** (trecho de [`docker-ps.txt`](../evidencias/docker-ps.txt)):

```
Rede: agrotech-lan | Driver: bridge | Sub-rede: 192.168.30.0/24 | Gateway: 192.168.30.1 | ip_range: 192.168.30.0/28
agrotech-dns  192.168.30.11/24
agrotech-ftp  192.168.30.13/24
agrotech-cliente  192.168.30.2/24
agrotech-web  192.168.30.12/24
agrotech-dhcp  192.168.30.10/24
```

![Containers no Docker Desktop](../evidencias/prints/docker-01-containers.png)

### D1 — DHCP

```powershell
docker compose exec cliente ip -4 addr show eth0          # IP inicial dado pelo Docker (.2)
docker compose exec cliente udhcpc -i eth0 -n -q -f       # pede IP ao nosso DHCP
docker compose exec cliente ip -4 addr show eth0          # novo IP
docker compose exec cliente ip route                      # gateway recebido
docker compose exec cliente cat /etc/resolv.conf          # DNS e domínio recebidos
docker compose logs dhcp                                  # lado do servidor
```

**Esperado:** o cliente troca o IP `.2` (Docker) por um IP entre `.100` e `.200`, com gateway 192.168.30.1, DNS 192.168.30.11 e domínio `agrotech.local`; o log do servidor mostra as 4 mensagens do DORA.

**Obtido** (trecho de [`teste-dhcp.txt`](../evidencias/teste-dhcp.txt)):

```
udhcpc: broadcasting discover
udhcpc: broadcasting select for 192.168.30.191, server 192.168.30.10
udhcpc: lease of 192.168.30.191 obtained from 192.168.30.10, lease time 43200
Configuracao aplicada: IP 192.168.30.191/24 | gateway 192.168.30.1 | DNS 192.168.30.11 | dominio agrotech.local | lease 43200s

default via 192.168.30.1 dev eth0
search agrotech.local
nameserver 192.168.30.11

dnsmasq-dhcp[1]: DHCPDISCOVER(eth0) ba:d7:df:e1:a6:bd
dnsmasq-dhcp[1]: DHCPOFFER(eth0) 192.168.30.191 ba:d7:df:e1:a6:bd
dnsmasq-dhcp[1]: DHCPREQUEST(eth0) 192.168.30.191 ba:d7:df:e1:a6:bd
dnsmasq-dhcp[1]: DHCPACK(eth0) 192.168.30.191 ba:d7:df:e1:a6:bd
```

O log completo também mostra as **opções** enviadas: `1 netmask 255.255.255.0`, `3 router 192.168.30.1`, `6 dns-server 192.168.30.11`, `15 domain-name agrotech.local`, `51 lease-time 12h`. O IP exato muda a cada execução (o dnsmasq sorteia dentro do pool).

![Log do DHCP no Docker Desktop](../evidencias/prints/docker-04-logs-dhcp-dora.png)

### D2 — DNS

```powershell
docker compose exec cliente nslookup intranet.agrotech.local 192.168.30.11
docker compose exec cliente nslookup erp.agrotech.local
docker compose exec cliente nslookup 192.168.30.12
docker compose exec cliente nslookup inexistente.agrotech.local
docker compose exec cliente nslookup www.google.com
```

**Esperado e obtido** ([`teste-dns.txt`](../evidencias/teste-dns.txt)):

| Consulta | Resposta | O que prova |
|---|---|---|
| `intranet.agrotech.local` | 192.168.30.12 | Registro A |
| `erp.agrotech.local` | `canonical name = intranet.agrotech.local` → 192.168.30.12 | Registro CNAME |
| `ftp`, `dhcp`, `fw` `.agrotech.local` | .13, .10, .1 | Demais registros A |
| `192.168.30.12` | `name = intranet.agrotech.local` | Registro reverso (PTR) |
| `inexistente.agrotech.local` | `NXDOMAIN` | A zona interna não vaza para a Internet |
| `www.google.com` | IPs públicos do Google (`Non-authoritative answer`) | Encaminhamento para 8.8.8.8 / 1.1.1.1 |

Os comandos sem `192.168.30.11` no final usam o DNS que o cliente **recebeu do DHCP**, o que prova a integração entre os dois serviços.

### D3 — Web

```powershell
docker compose exec cliente curl -sI http://192.168.30.12
docker compose exec cliente curl -s http://intranet.agrotech.local/saude
Invoke-WebRequest http://localhost:8080 -UseBasicParsing     # pelo Windows
```

**Obtido** ([`teste-web.txt`](../evidencias/teste-web.txt)):

```
HTTP/1.1 200 OK
Server: nginx/1.27.5
X-Servidor: agrotech-web (192.168.30.12)

OK - intranet AgroTech no ar
<title>Intranet AgroTech</title>

PS> Invoke-WebRequest http://localhost:8080
StatusCode: 200  Tamanho: 8250 bytes  X-Servidor: agrotech-web (192.168.30.12)
```

No log do nginx, os acessos do cliente aparecem com o IP recebido via DHCP (ex.: 192.168.30.191) e o acesso feito pelo Windows aparece vindo de **192.168.30.1**, o gateway, porque o Docker faz NAT da porta 8080.

![Intranet aberta no navegador](../evidencias/prints/docker-02-intranet-navegador.png)

### D4 — FTP (bônus)

```powershell
docker compose exec cliente curl -s --list-only ftp://agrotech:agrotech123@ftp.agrotech.local/arquivos/
docker compose exec cliente curl -s -T /tmp/relatorio.txt ftp://agrotech:agrotech123@ftp.agrotech.local/arquivos/
docker compose exec cliente curl -sS ftp://agrotech:senhaerrada@ftp.agrotech.local/
```

**Obtido** ([`teste-ftp.txt`](../evidencias/teste-ftp.txt)): listagem com `LEIA-ME.txt`, download do conteúdo, upload de `relatorio.txt` (aparece na listagem seguinte) e `curl: (67) Access denied: 530` com a senha errada. O log do vsftpd registra `FAIL LOGIN` para a tentativa inválida.

### Execução completa pelo script

```powershell
powershell -ExecutionPolicy Bypass -File .\docker\scripts\testar-tudo.ps1
```

```
  [PASSOU] DHCP (IP do pool .100-.200)
  [PASSOU] DNS (intranet -> 192.168.30.12)
  [PASSOU] Web (HTTP 200 no container e no host)
  [PASSOU] FTP (listar, baixar, enviar, negar senha errada)
```

![Script de testes no terminal](../evidencias/prints/docker-03-testar-tudo.png)

---

## 6.3 Testes no Packet Tracer

Roteiro detalhado: [`packet-tracer/README.md` › Executar os testes](../packet-tracer/README.md#9-executar-os-testes).

| # | Onde | Comando / ação | Esperado | Print |
|---|---|---|---|---|
| P1 | PC-ADM | `ipconfig /all` | IP 192.168.10.1xx, gateway .1, DNS 192.168.30.11 | `pt-02` |
| P2 | PC-ADM | `ipconfig /release` + `ipconfig /renew` | Novo IP recebido | `pt-02` |
| P3 | PC-TI | `ping 192.168.30.10` | Resposta (intra-VLAN) | `pt-03` |
| P4 | PC-ADM | `ping` no PC-COM (192.168.20.1xx) | Resposta (inter-VLAN) | `pt-04` |
| P5 | PC-ADM | `ping 192.168.30.12` | Resposta | `pt-04` |
| P6 | PC-ADM | `ping` no PC-FILIAL-ADM (192.168.110.1xx) | Resposta (matriz → filial) | `pt-05` |
| P7 | PC-FILIAL-ADM | `ping` no PC-ADM | Resposta (filial → matriz) | `pt-05` |
| P8 | PC-ADM | `tracert` até a filial | 192.168.10.1 → 203.0.113.2 → 198.51.100.2 → destino | `pt-05` |
| P9 | PC-ADM | `nslookup intranet.agrotech.local` | 192.168.30.12 | `pt-06` |
| P10 | PC-ADM | Navegador: `http://intranet.agrotech.local` | Página da intranet | `pt-07` |
| P11 | PC-FILIAL-ADM | Navegador: `http://erp.agrotech.local` | Página da intranet (CNAME, via WAN) | `pt-07` |
| P12 | PC-TI | `ftp 192.168.30.13` | Login e `dir` | `pt-08` |
| P13 | PC-ADM | `ping 8.8.8.8` | Resposta (Internet) | — |
| P14 | Laptop-Visitante | `ipconfig` | IP 192.168.50.1xx | `pt-09` |
| P15 | Laptop-Visitante | `ping 8.8.8.8` | Resposta | `pt-09` |
| P16 | Laptop-Visitante | `ping 192.168.10.1xx` / `ping 192.168.30.12` | **Bloqueado** (*Destination host unreachable*) | `pt-09` |
| P17 | Laptop-Visitante-Filial | `ping 8.8.8.8` / `ping 192.168.110.1xx` | Internet OK / interno bloqueado | — |
| P18 | R-MATRIZ | `show access-lists` | Contadores de *matches* na linha `deny` | `pt-10` |

Prints da simulação:

![Topologia no Packet Tracer](../evidencias/prints/pt-01-topologia.png)

![ipconfig no PC-ADM](../evidencias/prints/pt-02-ipconfig-pc-adm.png)

![Ping intra-VLAN](../evidencias/prints/pt-03-ping-intra-vlan.png)

![Ping inter-VLAN](../evidencias/prints/pt-04-ping-inter-vlan.png)

![Ping e tracert matriz-filial](../evidencias/prints/pt-05-ping-matriz-filial.png)

![nslookup](../evidencias/prints/pt-06-nslookup.png)

![Navegador com a intranet](../evidencias/prints/pt-07-navegador-intranet.png)

![Sessão FTP](../evidencias/prints/pt-08-ftp.png)

![Visitante bloqueado](../evidencias/prints/pt-09-visitante-bloqueado.png)

![show access-lists](../evidencias/prints/pt-10-show-access-lists.png)

![show vlan brief](../evidencias/prints/pt-11-show-vlan-brief.png)

![show ip route](../evidencias/prints/pt-12-show-ip-route.png)

![Pools DHCP no SRV-DHCP](../evidencias/prints/pt-13-dhcp-pools.png)

![Registros DNS no SRV-DNS](../evidencias/prints/pt-14-dns-registros.png)
