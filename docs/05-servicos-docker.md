# 5. Serviços de rede com Docker

## 5.1 Objetivo

Implementar na prática os serviços de infraestrutura da VLAN 30 da AgroTech, cada um em um container:

| Serviço | Container | IP fixo | Software | Porta | Papel na rede |
|---|---|---|---|---|---|
| **DHCP** | `agrotech-dhcp` | 192.168.30.10 | dnsmasq 2.90 (somente DHCP) | 67/UDP | Entrega IP, máscara, gateway, DNS e domínio aos clientes |
| **DNS** | `agrotech-dns` | 192.168.30.11 | dnsmasq 2.90 (somente DNS) | 53/UDP e TCP | Resolve `*.agrotech.local` e encaminha o resto à Internet |
| **Web** | `agrotech-web` | 192.168.30.12 | nginx 1.27 | 80/TCP (publicada no Windows em 8080) | Intranet corporativa |
| **FTP** (bônus) | `agrotech-ftp` | 192.168.30.13 | vsftpd | 21/TCP + 21100–21110 (passivo) | Troca de arquivos (manuais, catálogos, laudos) |
| Cliente de teste | `agrotech-cliente` | via DHCP | Alpine + udhcpc, nslookup, dig, curl | — | Simula o PC de um funcionário |

Os quatro serviços foram testados e funcionaram (ver [06 — Testes e evidências](06-testes-e-evidencias.md)).

## 5.2 Arquitetura

```mermaid
flowchart LR
    subgraph HOST["Windows + Docker Desktop (WSL 2)"]
        NAV["Navegador<br/>http://localhost:8080"]
        subgraph LAN["Rede Docker agrotech-lan — bridge 192.168.30.0/24 (= VLAN 30)"]
            GW["Gateway 192.168.30.1<br/>(bridge do Docker / NAT)"]
            DHCP["agrotech-dhcp<br/>192.168.30.10<br/>dnsmasq DHCP"]
            DNS["agrotech-dns<br/>192.168.30.11<br/>dnsmasq DNS"]
            WEB["agrotech-web<br/>192.168.30.12<br/>nginx"]
            FTP["agrotech-ftp<br/>192.168.30.13<br/>vsftpd"]
            CLI["agrotech-cliente<br/>IP do pool .100–.200"]
        end
    end
    INTERNET(("Internet<br/>8.8.8.8 / 1.1.1.1"))
    CLI -- "1. DHCP DISCOVER (broadcast)" --> DHCP
    CLI -- "2. nslookup intranet.agrotech.local" --> DNS
    CLI -- "3. HTTP GET /" --> WEB
    CLI -- "4. FTP" --> FTP
    DNS -- "nomes externos" --> GW --> INTERNET
    NAV -- "porta 8080 → 80" --> WEB
```

A rede `agrotech-lan` é um **switch virtual** (bridge Linux) criado pelo Docker. Ela usa a mesma sub-rede, o mesmo gateway e os mesmos IPs fixos da VLAN 30 do [plano de IP](04-plano-ip.md). O gateway 192.168.30.1 é a própria bridge do Docker, que faz NAT para a Internet. É por ele que o DNS alcança 8.8.8.8 e 1.1.1.1.

## 5.3 Estrutura dos arquivos

```
docker/
├── docker-compose.yml        # define rede, serviços, IPs e volumes (comentado linha a linha)
├── dhcp/
│   ├── Dockerfile            # Alpine + dnsmasq
│   └── dnsmasq.conf          # configuração do DHCP
├── dns/
│   ├── Dockerfile            # Alpine + dnsmasq + dig
│   ├── dnsmasq.conf          # configuração do DNS
│   └── agrotech.hosts        # registros A da zona agrotech.local
├── web/
│   ├── nginx.conf            # site da intranet
│   └── html/index.html       # página da intranet
├── ftp/
│   ├── Dockerfile            # Alpine + vsftpd
│   ├── entrypoint.sh         # cria o usuário e inicia o vsftpd
│   └── vsftpd.conf           # configuração do FTP
├── cliente/
│   ├── Dockerfile            # Alpine + ferramentas de teste
│   └── udhcpc.script         # aplica IP/gateway/DNS recebidos do DHCP
└── scripts/
    ├── subir.ps1             # sobe os serviços
    ├── testar-tudo.ps1       # roda todos os testes e grava as evidências
    └── derrubar.ps1          # remove containers e rede
```

As configurações ficam **versionadas no Git** e são **montadas como volumes somente leitura** (`:ro`) nos containers. Para mudar algo (por exemplo, um registro DNS), basta editar o arquivo e recriar o container, sem reconstruir a imagem.

## 5.4 Como reproduzir do zero

**Pré-requisitos:** Windows 10/11 com Docker Desktop instalado e aberto (ícone da baleia "Running"), Git e acesso à Internet (para baixar as imagens base `alpine:3.20` e `nginx:1.27-alpine`).

```powershell
# 1. Baixar o repositório
git clone https://github.com/<usuario>/agrotech-infraestrutura-redes.git
cd agrotech-infraestrutura-redes

# 2. Rodar todos os testes (sobe os serviços, o cliente e grava evidencias/*.txt)
powershell -ExecutionPolicy Bypass -File .\docker\scripts\testar-tudo.ps1

# 3. Abrir a intranet no navegador do Windows
start http://localhost:8080

# 4. Ver os logs do DHCP (processo DORA)
docker compose -f docker\docker-compose.yml logs dhcp

# 5. Desligar tudo
powershell -ExecutionPolicy Bypass -File .\docker\scripts\derrubar.ps1
```

O `-ExecutionPolicy Bypass` libera a execução do script só naquela chamada, sem alterar a política do Windows.

### Passo a passo manual (sem o script)

Dentro da pasta `docker/`:

```powershell
docker compose up -d --build                 # constrói as imagens e sobe DHCP, DNS, Web e FTP
docker compose ps                            # confere se os 4 estão "Up"
docker compose --profile test up -d cliente  # sobe o cliente de teste

# Teste 1 - DHCP: o cliente pede um IP
docker compose exec cliente udhcpc -i eth0 -n -q -f
docker compose exec cliente ip -4 addr show eth0
docker compose exec cliente cat /etc/resolv.conf
docker compose logs dhcp                     # DHCPDISCOVER / OFFER / REQUEST / ACK

# Teste 2 - DNS
docker compose exec cliente nslookup intranet.agrotech.local 192.168.30.11
docker compose exec cliente nslookup erp.agrotech.local
docker compose exec cliente nslookup www.google.com

# Teste 3 - Web
docker compose exec cliente curl -I http://192.168.30.12
docker compose exec cliente curl http://intranet.agrotech.local/saude

# Teste 4 - FTP
docker compose exec cliente curl --list-only ftp://agrotech:agrotech123@ftp.agrotech.local/arquivos/

docker compose --profile test down           # remove tudo
```

## 5.5 Explicação das configurações

### 5.5.1 `docker-compose.yml`

| Trecho | O que faz |
|---|---|
| `name: agrotech` | Nome do projeto Compose (prefixo dos recursos). |
| `services:` | Lista dos containers. Cada bloco abaixo é um serviço. |
| `build: ./dhcp` | Constrói a imagem a partir do `Dockerfile` da pasta `dhcp/`. |
| `image: agrotech/dhcp:1.0` | Nome e versão dados à imagem construída. |
| `container_name: agrotech-dhcp` | Nome fixo do container, como aparece no Docker Desktop. |
| `hostname: dhcp` | Nome da "máquina" dentro do container. |
| `cap_add: [NET_ADMIN, NET_RAW]` | Permissões extras do kernel. O DHCP precisa responder a clientes que ainda não têm IP (manipula a tabela ARP) e faz um *ping* de verificação antes de oferecer um endereço. |
| `volumes: - ./dhcp/dnsmasq.conf:/etc/dnsmasq.conf:ro` | Monta o arquivo do repositório dentro do container, somente leitura. |
| `networks: agrotech-lan: ipv4_address: 192.168.30.10` | Liga o container à rede da VLAN 30 com IP fixo. |
| `restart: unless-stopped` | Reinicia automaticamente o container se ele cair. |
| `image: nginx:1.27-alpine` | O Web usa a imagem oficial do nginx, com versão fixa para ser reprodutível. |
| `ports: - "8080:80"` | Publica a porta 80 do container na porta 8080 do Windows. |
| `environment: FTP_USER / FTP_PASS` | Usuário e senha do FTP (de demonstração), lidos pelo `entrypoint.sh`. |
| `profiles: ["test"]` | O cliente só sobe quando pedido (`--profile test`), não no `up` normal. |
| `depends_on:` | O cliente só é criado depois de DHCP, DNS e Web. |
| `networks: agrotech-lan: name: agrotech-lan` | Nome fixo da rede, sem o prefixo do projeto. |
| `driver: bridge` | Switch virtual isolado da rede física. |
| `subnet: 192.168.30.0/24` | Mesma sub-rede da VLAN 30. |
| `gateway: 192.168.30.1` | Mesmo gateway do plano de IP. |
| `ip_range: 192.168.30.0/28` | O Docker só sorteia IPs automáticos entre .1 e .14, longe do pool do nosso DHCP (.100–.200). Assim o Docker e o dnsmasq nunca entregam o mesmo endereço. |

### 5.5.2 DHCP — `docker/dhcp/dnsmasq.conf`

| Linha | Significado |
|---|---|
| `port=0` | Desliga o DNS do dnsmasq: este container faz **só DHCP**. |
| `interface=eth0` | Atende pedidos só na interface ligada à `agrotech-lan`. |
| `dhcp-range=192.168.30.100,192.168.30.200,255.255.255.0,12h` | Pool de .100 a .200, máscara /24, concessão (*lease*) de 12 horas. |
| `dhcp-option=option:router,192.168.30.1` | Opção DHCP 3: gateway padrão. |
| `dhcp-option=option:dns-server,192.168.30.11` | Opção DHCP 6: servidor DNS (o container DNS). |
| `dhcp-option=option:domain-name,agrotech.local` | Opção DHCP 15: sufixo de domínio. |
| `domain=agrotech.local` | Domínio local do servidor. |
| `dhcp-authoritative` | Servidor oficial do segmento: responde imediatamente, inclusive a clientes com concessão antiga. |
| `dhcp-leasefile=/var/lib/misc/dnsmasq.leases` | Arquivo onde as concessões são registradas. |
| `log-dhcp` | Registra cada etapa do DORA e as opções enviadas. |
| `log-facility=-` | Envia o log para a saída padrão (visível com `docker compose logs dhcp`). |
| `dhcp-broadcast` | Envia OFFER e ACK em broadcast. Sem isso, a primeira resposta era perdida na bridge do Docker e o cliente precisava repetir o DISCOVER (ver [07](07-dificuldades-e-decisoes.md)). |

### 5.5.3 DNS — `docker/dns/dnsmasq.conf` e `agrotech.hosts`

| Linha | Significado |
|---|---|
| `port=53` | Escuta consultas DNS na porta padrão. |
| `no-resolv` | Não usa o `/etc/resolv.conf` do container; os servidores externos são definidos abaixo. |
| `server=8.8.8.8` / `server=1.1.1.1` | *Forwarders*: consultas a nomes externos vão para o Google DNS e o Cloudflare DNS. |
| `local=/agrotech.local/` | A zona `agrotech.local` é respondida **só localmente**: um nome inexistente retorna NXDOMAIN em vez de ser enviado à Internet. |
| `domain=agrotech.local` | Domínio local. |
| `domain-needed` | Não encaminha à Internet nomes sem ponto (ex.: `intranet`). |
| `bogus-priv` | Não encaminha consultas reversas de IPs privados (192.168.x.x) à Internet. |
| `no-hosts` | Ignora o `/etc/hosts` interno do container, para publicar só os registros da AgroTech. |
| `addn-hosts=/etc/agrotech.hosts` | Lê os registros A do arquivo `agrotech.hosts`. O registro reverso (PTR) é criado automaticamente. |
| `cname=erp.agrotech.local,intranet.agrotech.local` | Registro CNAME: `erp` é um apelido da intranet. |
| `no-dhcp-interface=eth0` | Garante que este container nunca responde DHCP, evitando conflito com o servidor DHCP. |
| `log-queries` / `log-facility=-` | Registra cada consulta na saída do container. |

Registros da zona (`agrotech.hosts`):

| Nome | Tipo | Valor |
|---|---|---|
| fw.agrotech.local | A | 192.168.30.1 |
| dhcp.agrotech.local | A | 192.168.30.10 |
| dns.agrotech.local | A | 192.168.30.11 |
| intranet.agrotech.local | A | 192.168.30.12 |
| ftp.agrotech.local | A | 192.168.30.13 |
| erp.agrotech.local | CNAME | intranet.agrotech.local |

### 5.5.4 Web — `docker/web/nginx.conf`

| Linha | Significado |
|---|---|
| `listen 80;` | Escuta na porta 80 do container. |
| `server_name intranet.agrotech.local erp.agrotech.local ...;` | Nomes pelos quais o site responde. |
| `root /usr/share/nginx/html;` | Pasta com a página (montada a partir de `docker/web/html`). |
| `add_header X-Servidor "agrotech-web (192.168.30.12)" always;` | Cabeçalho HTTP que identifica o servidor (aparece no `curl -I`). |
| `location = /saude { return 200 "OK ..."; }` | Endereço de verificação de saúde, usado nos testes automáticos. |
| `access_log /dev/stdout;` | Log de acessos na saída do container (`docker compose logs web`). |

### 5.5.5 FTP — `docker/ftp/vsftpd.conf`

| Linha | Significado |
|---|---|
| `listen=YES`, `background=NO` | Modo independente, em primeiro plano (exigência do Docker). |
| `anonymous_enable=NO`, `local_enable=YES` | Sem acesso anônimo; só usuários cadastrados. |
| `write_enable=YES`, `local_umask=022` | Permite upload; arquivos novos com permissão 644. |
| `chroot_local_user=YES` | O usuário fica preso na própria pasta. |
| `pasv_enable=YES`, `pasv_min_port=21100`, `pasv_max_port=21110` | Modo passivo: o servidor abre uma porta de dados nessa faixa. |
| `seccomp_sandbox=NO` | Desliga um recurso de isolamento do vsftpd incompatível com alguns kernels de container. |
| `xferlog_enable`, `log_ftp_protocol`, `vsftpd_log_file=/proc/1/fd/1` | Registra comandos e transferências na saída do container. |

### 5.5.6 Cliente de teste — `docker/cliente/`

O cliente é um Alpine Linux com `udhcpc` (cliente DHCP do BusyBox), `nslookup`/`dig` e `curl`. Ele recebe um IP inicial do Docker (faixa .0/28) e, ao rodar `udhcpc`, **troca esse IP pelo endereço entregue pelo nosso DHCP**. O `udhcpc.script` aplica IP, máscara, gateway e grava o DNS em `/etc/resolv.conf`. A partir daí, o cliente usa o nosso DNS para tudo, como um PC real da empresa.

## 5.6 Como os serviços se encaixam no projeto real

Em produção, os mesmos arquivos de configuração rodariam no **servidor de infraestrutura** do rack (Ubuntu Server + Docker, IP 192.168.30.9), com duas diferenças:

1. A rede dos containers usaria o driver **macvlan** (ou ipvlan) sobre a interface da VLAN 30, para que cada container tenha um IP "real" na rede física.
2. O DHCP atenderia **todas as VLANs**, com um `dhcp-range` por rede (ex.: `dhcp-range=set:vlan10,192.168.10.100,192.168.10.200,12h` e a opção de gateway correspondente), recebendo os pedidos encaminhados pelo `ip helper-address` / DHCP Relay do firewall. É exatamente o que a simulação do Packet Tracer demonstra.

As limitações do Docker Desktop que levaram a usar a rede bridge estão em [07 — Dificuldades e decisões](07-dificuldades-e-decisoes.md).
