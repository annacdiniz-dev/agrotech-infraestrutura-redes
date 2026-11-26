# 3. Plano de endereçamento IP e segmentação

> **Itens do enunciado atendidos neste documento** (requisito obrigatório 3 — critério "Plano de endereçamento IP e segmentação", 2,0 pts)
>
> | Item pedido | Seção |
> |---|---|
> | Definição das redes e sub-redes | [3.3](#33-matriz-goiânia), [3.4](#34-filial-anápolis), [3.5](#35-links-wan) |
> | Endereços IP e máscaras de rede | [3.2](#32-máscara-24-cálculo), tabelas de 3.3 a 3.6 |
> | Identificação dos gateways | Coluna "Gateway" de 3.3 e 3.4; regra em [3.1](#31-regras-do-plano) |
> | Distribuição dos endereços IP por setor ou departamento | [3.6](#36-endereços-fixos) e [3.7](#37-distribuição-por-setor) |

## 3.1 Regras do plano

1. **Faixa privada 192.168.0.0/16** (RFC 1918) para todas as redes internas.
2. **Uma sub-rede /24 por VLAN**, com o **terceiro octeto igual ao número da VLAN**: VLAN 10 → 192.168.**10**.0/24, VLAN 110 → 192.168.**110**.0/24. Olhando um IP, já se sabe a VLAN e o setor.
3. **Filial = matriz + 100** (VLANs 110, 120, 150), o que deixa claro, pelo IP, em que unidade o dispositivo está.
4. **Gateway sempre `.1`** (subinterface do firewall/roteador).
5. **Mesma divisão interna em todas as sub-redes:**

| Faixa | Uso |
|---|---|
| `.1` | Gateway (firewall pfSense / subinterface do roteador) |
| `.2` – `.9` | Equipamentos de rede (gerência de switches, controladora de APs) |
| `.10` – `.99` | IPs fixos: servidores, impressoras, NVR, câmeras, PABX |
| `.100` – `.200` | **Pool DHCP** (101 endereços) |
| `.201` – `.254` | Reserva (expansão de IPs fixos ou do pool) |
| `.255` | Broadcast |

6. **Links WAN em /30** (2 hosts úteis, exatamente as duas pontas), usando as faixas de documentação 203.0.113.0/24 e 198.51.100.0/24 (RFC 5737), por se tratar de um projeto acadêmico.

## 3.2 Máscara /24: cálculo

| Item | Valor |
|---|---|
| Notação CIDR | /24 |
| Máscara decimal | 255.255.255.0 |
| Máscara binária | 11111111.11111111.11111111.00000000 |
| Bits de host | 32 − 24 = 8 |
| Endereços na sub-rede | 2⁸ = 256 |
| Hosts úteis | 256 − 2 = **254** (descontando rede e broadcast) |

Exemplo da VLAN 10: rede **192.168.10.0**, primeiro host 192.168.10.1, último host 192.168.10.254, broadcast **192.168.10.255**.

## 3.3 Matriz (Goiânia)

| VLAN | Setor(es) | Rede | Máscara | Gateway | Broadcast | Pool DHCP | Hosts úteis | Uso atual |
|---|---|---|---|---|---|---|---|---|
| 10 | Administrativo / Financeiro | 192.168.10.0/24 | 255.255.255.0 | 192.168.10.1 | 192.168.10.255 | .100 – .200 | 254 | 9 |
| 20 | Comercial / RH / Recepção (+ Reuniões, Oficina, Estoque, Wi-Fi corporativo) | 192.168.20.0/24 | 255.255.255.0 | 192.168.20.1 | 192.168.20.255 | .100 – .200 | 254 | ~35 |
| 30 | TI / Servidores | 192.168.30.0/24 | 255.255.255.0 | 192.168.30.1 | 192.168.30.255 | .100 – .200 | 254 | 12 |
| 40 | Câmeras IP / IoT | 192.168.40.0/24 | 255.255.255.0 | 192.168.40.1 | 192.168.40.255 | .100 – .200 | 254 | 9 |
| 50 | Wi-Fi Visitantes | 192.168.50.0/24 | 255.255.255.0 | 192.168.50.1 | 192.168.50.255 | .100 – .200 | 254 | 10–20 |
| 60 | VoIP | 192.168.60.0/24 | 255.255.255.0 | 192.168.60.1 | 192.168.60.255 | .100 – .200 | 254 | 22 |

## 3.4 Filial (Anápolis)

| VLAN | Setor(es) | Rede | Máscara | Gateway | Broadcast | Pool DHCP | Hosts úteis | Uso atual |
|---|---|---|---|---|---|---|---|---|
| 110 | Administrativo / Atendimento | 192.168.110.0/24 | 255.255.255.0 | 192.168.110.1 | 192.168.110.255 | .100 – .200 | 254 | ~16 |
| 120 | Oficina / Estoque | 192.168.120.0/24 | 255.255.255.0 | 192.168.120.1 | 192.168.120.255 | .100 – .200 | 254 | ~6 |
| 150 | Wi-Fi Visitantes | 192.168.150.0/24 | 255.255.255.0 | 192.168.150.1 | 192.168.150.255 | .100 – .200 | 254 | ~5 |

Na filial, os 6 telefones IP ficam provisoriamente nas VLANs de dados (110 e 120), com marcação de prioridade (DSCP EF) feita pelo próprio aparelho. A VLAN **160** está reservada para VoIP da filial e a **140** para câmeras da filial, na próxima fase.

## 3.5 Links WAN

| Link | Rede | Máscara | Ponta A | Ponta B |
|---|---|---|---|---|
| Matriz ↔ provedor | 203.0.113.0/30 | 255.255.255.252 | R-MATRIZ Gi0/1 = **203.0.113.1** | R-ISP Gi0/0 = **203.0.113.2** |
| Provedor ↔ filial | 198.51.100.0/30 | 255.255.255.252 | R-ISP Gi0/1 = **198.51.100.1** | R-FILIAL Gi0/1 = **198.51.100.2** |
| Túnel GRE (opcional, PT) | 172.16.0.0/30 | 255.255.255.252 | R-MATRIZ Tunnel0 = 172.16.0.1 | R-FILIAL Tunnel0 = 172.16.0.2 |
| "Internet" simulada | 8.8.8.8/32 | 255.255.255.255 | Loopback0 do R-ISP | — |

Cálculo do /30: 32 − 30 = 2 bits de host → 4 endereços → 2 hosts úteis. Em 203.0.113.0/30: rede .0, hosts .1 e .2, broadcast .3. Usar /30 evita desperdiçar endereços públicos num link que só tem duas pontas.

## 3.6 Endereços fixos

### VLAN 30 — TI / Servidores (matriz)

| IP | Nome DNS | Dispositivo |
|---|---|---|
| 192.168.30.1 | `fw.agrotech.local` | Gateway (firewall pfSense / subinterface Gi0/0.30 do R-MATRIZ) |
| 192.168.30.2 | — | SW-CORE (gerência) |
| 192.168.30.3 | — | SW-DIST1 (gerência) |
| 192.168.30.4 | — | SW-DIST2 (gerência) |
| 192.168.30.5 | — | Omada Controller (gerência dos APs) — reservado |
| 192.168.30.9 | — | Servidor de infraestrutura (host físico do Docker) |
| **192.168.30.10** | `dhcp.agrotech.local` | **Servidor DHCP** (container `agrotech-dhcp` / SRV-DHCP no PT) |
| **192.168.30.11** | `dns.agrotech.local` | **Servidor DNS** (container `agrotech-dns` / SRV-DNS) |
| **192.168.30.12** | `intranet.agrotech.local`, `erp.agrotech.local` (CNAME) | **Servidor Web / Intranet** (container `agrotech-web` / SRV-WEB) |
| **192.168.30.13** | `ftp.agrotech.local` | **Servidor FTP** (container `agrotech-ftp` / SRV-FTP) |
| 192.168.30.20 | — | NAS de backup |

### Demais VLANs

| IP | Dispositivo |
|---|---|
| 192.168.10.10 | Impressora Administração/Financeiro |
| 192.168.20.10 | Impressora Recepção |
| 192.168.20.11 | Impressora Comercial/RH |
| 192.168.20.12 | Impressora Oficina Técnica |
| 192.168.20.13 | Impressora de etiquetas do Estoque |
| 192.168.40.10 | NVR (gravador das câmeras) |
| 192.168.40.21 – .28 | Câmeras IP 1 a 8 |
| 192.168.60.10 | PABX IP (central telefônica) |
| 192.168.110.2 | SW-FILIAL (gerência) |
| 192.168.110.10 | Impressora Atendimento |
| 192.168.110.11 | Impressora Escritório |
| 192.168.120.10 | Impressora Oficina (filial) |

## 3.7 Distribuição por setor

| Unidade | Setor | VLAN | Rede | Gateway | Forma de endereçamento |
|---|---|---|---|---|---|
| Matriz | Recepção | 20 | 192.168.20.0/24 | 192.168.20.1 | DHCP (PCs) + fixo (impressora) |
| Matriz | Administração | 10 | 192.168.10.0/24 | 192.168.10.1 | DHCP + fixo (impressora) |
| Matriz | Financeiro | 10 | 192.168.10.0/24 | 192.168.10.1 | DHCP |
| Matriz | Comercial | 20 | 192.168.20.0/24 | 192.168.20.1 | DHCP + fixo (impressora) |
| Matriz | RH | 20 | 192.168.20.0/24 | 192.168.20.1 | DHCP |
| Matriz | Sala de Reuniões | 20 | 192.168.20.0/24 | 192.168.20.1 | DHCP |
| Matriz | TI | 30 | 192.168.30.0/24 | 192.168.30.1 | DHCP (PCs) + fixo (servidores, switches) |
| Matriz | Oficina Técnica | 20 | 192.168.20.0/24 | 192.168.20.1 | DHCP + fixo (impressora) |
| Matriz | Estoque | 20 | 192.168.20.0/24 | 192.168.20.1 | DHCP + fixo (impressora) |
| Matriz | Câmeras / NVR | 40 | 192.168.40.0/24 | 192.168.40.1 | Fixo |
| Matriz | Telefones IP | 60 | 192.168.60.0/24 | 192.168.60.1 | DHCP |
| Matriz | Visitantes (Wi-Fi) | 50 | 192.168.50.0/24 | 192.168.50.1 | DHCP |
| Filial | Atendimento | 110 | 192.168.110.0/24 | 192.168.110.1 | DHCP + fixo (impressora) |
| Filial | Escritório Administrativo | 110 | 192.168.110.0/24 | 192.168.110.1 | DHCP + fixo (impressora) |
| Filial | Oficina Técnica | 120 | 192.168.120.0/24 | 192.168.120.1 | DHCP + fixo (impressora) |
| Filial | Estoque | 120 | 192.168.120.0/24 | 192.168.120.1 | DHCP |
| Filial | Visitantes (Wi-Fi) | 150 | 192.168.150.0/24 | 192.168.150.1 | DHCP |

Todos os clientes DHCP recebem: **gateway** = `.1` da própria VLAN, **DNS** = 192.168.30.11, **domínio** = `agrotech.local`, **concessão** de 12 horas.

## 3.8 Justificativa das decisões

- **Por que /24 em todas as VLANs, e não máscaras menores (VLSM)?** A faixa privada 192.168.0.0/16 tem 256 redes /24 disponíveis; economizar endereços não é necessário. O /24 é a máscara mais fácil de ler e administrar (o último octeto é o host), e com 254 hosts por VLAN comporta com folga a meta de **150 dispositivos**: mesmo que todo o crescimento caísse numa única VLAN, ela ainda teria espaço.
- **Por que o terceiro octeto igual à VLAN?** Reduz erros de configuração e acelera o diagnóstico: ao ver `192.168.40.23` no log do firewall, a equipe sabe que é uma câmera da matriz.
- **Por que o pool DHCP é `.100`–`.200` e não a rede inteira?** Separa IPs dinâmicos de fixos e deixa espaço para os dois crescerem. Os 101 endereços do pool superam o uso atual de qualquer VLAN.
- **Por que DHCP centralizado em vez de um servidor por VLAN?** Um único servidor (192.168.30.10) com um pool por rede, alcançado pelo *relay* (`ip helper-address`) dos roteadores, simplifica a administração. Os registros de concessões ficam num só lugar.
- **Por que /30 na WAN?** Um link ponto a ponto só precisa de dois endereços.
- **Por que endereços de documentação na WAN?** São faixas reservadas para exemplos (RFC 5737), que nunca aparecem na Internet real. No projeto implantado, seriam substituídas pelos IPs fixos contratados com a Vivo Empresas.

## 3.9 Correspondência com o ambiente Docker

A rede Docker `agrotech-lan` reproduz a **VLAN 30**: mesma sub-rede (192.168.30.0/24), mesmo gateway (.1), mesmos IPs fixos de servidores (.10 a .13) e mesmo pool DHCP (.100 a .200). O Docker só atribui IPs automáticos dentro de `ip_range: 192.168.30.0/28` (.1 a .14), longe do pool. Detalhes em [4 — Configuração dos serviços](04-configuracao-dos-servicos-docker.md).
