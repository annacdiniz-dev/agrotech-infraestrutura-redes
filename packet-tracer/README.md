# Guia do Cisco Packet Tracer — Rede AgroTech (matriz + filial)

Este guia monta, passo a passo, a simulação completa da rede da AgroTech no **Cisco Packet Tracer 8.x**. Ele supõe que você nunca montou uma rede desse tamanho no Packet Tracer. Tempo estimado: **1h30 a 2h**.

Arquivos usados:

- [`configs/`](configs/): comandos prontos para colar na aba CLI de cada roteador/switch.
- [`configs/SRV-INFRA.md`](configs/SRV-INFRA.md): valores para preencher nos servidores (DHCP, DNS, HTTP, FTP).
- Resultado final: salvar como `packet-tracer/agrotech.pkt`.

> **Importante:** os arquivos de configuração foram escritos seguindo a sintaxe do Cisco IOS, mas **não puderam ser executados automaticamente**, porque o Packet Tracer só funciona pela interface gráfica. Se alguma linha der `% Invalid input detected`, veja a seção [Se der errado](#11-se-der-errado).

---

## Sumário

1. [Visão geral da topologia](#1-visão-geral-da-topologia)
2. [Criar os dispositivos](#2-criar-os-dispositivos)
3. [Nomear cada dispositivo](#3-nomear-cada-dispositivo)
4. [Cabear](#4-cabear)
5. [Configurar switches e roteadores (colar os comandos)](#5-configurar-switches-e-roteadores-colar-os-comandos)
6. [Configurar os servidores](#6-configurar-os-servidores)
7. [Configurar o Wi-Fi de visitantes](#7-configurar-o-wi-fi-de-visitantes)
8. [Colocar os PCs em DHCP](#8-colocar-os-pcs-em-dhcp)
9. [Executar os testes](#9-executar-os-testes)
10. [Tirar os prints e salvar o arquivo](#10-tirar-os-prints-e-salvar-o-arquivo)
11. [Se der errado](#11-se-der-errado)

---

## 1. Visão geral da topologia

```
                 MATRIZ (Goiânia)                         PROVEDOR              FILIAL (Anápolis)

 PC-ADM(V10) ─┐                                                                  ┌─ PC-FILIAL-ADM (V110)
 PC-COM(V20) ─┤                                                                  ├─ PC-FILIAL-OFI (V120)
 IP-PHONE(V60)┼─ SW-DIST1 ─┐                                                     ├─ AP-FILIAL (V150) ))) Laptop-Visitante-Filial
 AP-VISIT(V50)┘            │                                                     │
   ))) Laptop-Visitante    ├─ SW-CORE ─ R-MATRIZ ──── R-ISP ──── R-FILIAL ─ SW-FILIAL
                           │   (trunk)   Gi0/1   WAN   (8.8.8.8)  WAN  Gi0/0
 SRV-DHCP .10 ─┐           │           203.0.113.0/30      198.51.100.0/30
 SRV-DNS  .11 ─┤           │
 SRV-WEB  .12 ─┼─ SW-DIST2 ┘
 SRV-FTP  .13 ─┤
 PC-TI   (V30)─┤
 PC-CAM  (V40)─┘
```

- **Router-on-a-stick:** cada roteador tem um único cabo para o switch (trunk 802.1Q) e uma subinterface por VLAN. A subinterface é o gateway (.1) daquela VLAN.
- **DHCP centralizado:** o SRV-DHCP (192.168.30.10) atende todas as VLANs, inclusive as da filial, porque os roteadores repassam os pedidos com `ip helper-address 192.168.30.10`.
- **R-ISP** faz o papel do provedor e da Internet (a interface Loopback0 com o IP 8.8.8.8 simula um site externo).

---

## 2. Criar os dispositivos

A barra de dispositivos fica no **canto inferior esquerdo** da tela. Ela tem duas linhas: em cima, a **categoria**; embaixo, a **subcategoria**. Ao clicar numa subcategoria, os modelos aparecem na caixa ao lado. Para colocar um dispositivo: clique no modelo e depois clique na área de trabalho (ou arraste).

| Quantidade | Dispositivo | Onde clicar |
|---|---|---|
| 3 | Roteador **2911** | Network Devices (ícone de roteador) → **Routers** → **2911** |
| 4 | Switch **2960** | Network Devices → **Switches** → **2960** (2960-24TT) |
| 4 | Servidor | End Devices (ícone de computador) → **End Devices** → **Server** (Server-PT) |
| 6 | PC | End Devices → End Devices → **PC** (PC-PT) |
| 2 | Laptop | End Devices → End Devices → **Laptop** (Laptop-PT) |
| 1 | Telefone IP (opcional) | End Devices → End Devices → **IP Phone** (7960) |
| 2 | Access Point | Network Devices → **Wireless Devices** → **AccessPoint-PT** |

**Dica de organização:** posicione a matriz à esquerda, o R-ISP no meio e a filial à direita, como no desenho acima. Depois você pode desenhar retângulos para delimitar "Matriz" e "Filial" (barra superior → ícone de retângulo **Draw Rectangle**) e escrever rótulos com a ferramenta de nota (**Place Note**, tecla `N`).

---

## 3. Nomear cada dispositivo

Para cada dispositivo: **clique uma vez** nele → aba **Config** → seção **GLOBAL / Settings** → campo **Display Name** → digite o nome → aperte Enter.

Nomes a usar (exatamente assim):

| Tipo | Nomes |
|---|---|
| Roteadores 2911 | `R-MATRIZ`, `R-ISP`, `R-FILIAL` |
| Switches 2960 | `SW-CORE`, `SW-DIST1`, `SW-DIST2`, `SW-FILIAL` |
| Servidores | `SRV-DHCP`, `SRV-DNS`, `SRV-WEB`, `SRV-FTP` |
| PCs | `PC-ADM`, `PC-COM`, `PC-TI`, `PC-CAM`, `PC-FILIAL-ADM`, `PC-FILIAL-OFI` |
| Laptops | `Laptop-Visitante`, `Laptop-Visitante-Filial` |
| Access Points | `AP-VISITANTES`, `AP-FILIAL` |
| Telefone | `IP-PHONE` |

O *Display Name* é só o rótulo do desenho. O nome interno dos roteadores e switches (o `hostname`) é definido pelos comandos do passo 5.

---

## 4. Cabear

Clique no ícone do **raio** (categoria **Connections**, na barra inferior). Escolha o tipo de cabo, clique no **primeiro dispositivo**, escolha a **porta** no menu que aparece, depois clique no **segundo dispositivo** e escolha a porta.

- **Copper Straight-Through** (linha preta contínua): dispositivos **diferentes** (roteador↔switch, PC↔switch, servidor↔switch, AP↔switch).
- **Copper Cross-Over** (linha preta tracejada): dispositivos **iguais** (switch↔switch, roteador↔roteador).

Não use o cabo "automático" (raio amarelo), porque ele escolhe a primeira porta livre e as portas precisam bater com as configurações.

| # | Dispositivo A | Porta A | Dispositivo B | Porta B | Cabo |
|---|---|---|---|---|---|
| 1 | R-MATRIZ | GigabitEthernet0/0 | SW-CORE | FastEthernet0/1 | Straight-Through |
| 2 | R-MATRIZ | GigabitEthernet0/1 | R-ISP | GigabitEthernet0/0 | Cross-Over |
| 3 | R-ISP | GigabitEthernet0/1 | R-FILIAL | GigabitEthernet0/0 | Cross-Over |
| 4 | SW-CORE | FastEthernet0/2 | SW-DIST1 | FastEthernet0/1 | Cross-Over |
| 5 | SW-CORE | FastEthernet0/3 | SW-DIST2 | FastEthernet0/1 | Cross-Over |
| 6 | SW-DIST1 | FastEthernet0/2 | PC-ADM | FastEthernet0 | Straight-Through |
| 7 | SW-DIST1 | FastEthernet0/3 | PC-COM | FastEthernet0 | Straight-Through |
| 8 | SW-DIST1 | FastEthernet0/17 | IP-PHONE (opcional) | Switch | Straight-Through |
| 9 | SW-DIST1 | FastEthernet0/4 | AP-VISITANTES | Port 0 | Straight-Through |
| 10 | SW-DIST2 | FastEthernet0/2 | SRV-DHCP | FastEthernet0 | Straight-Through |
| 11 | SW-DIST2 | FastEthernet0/3 | SRV-DNS | FastEthernet0 | Straight-Through |
| 12 | SW-DIST2 | FastEthernet0/4 | SRV-WEB | FastEthernet0 | Straight-Through |
| 13 | SW-DIST2 | FastEthernet0/5 | SRV-FTP | FastEthernet0 | Straight-Through |
| 14 | SW-DIST2 | FastEthernet0/6 | PC-TI | FastEthernet0 | Straight-Through |
| 15 | SW-DIST2 | FastEthernet0/7 | PC-CAM | FastEthernet0 | Straight-Through |
| 16 | R-FILIAL | GigabitEthernet0/1 | SW-FILIAL | FastEthernet0/1 | Straight-Through |
| 17 | SW-FILIAL | FastEthernet0/2 | PC-FILIAL-ADM | FastEthernet0 | Straight-Through |
| 18 | SW-FILIAL | FastEthernet0/3 | PC-FILIAL-OFI | FastEthernet0 | Straight-Through |
| 19 | SW-FILIAL | FastEthernet0/4 | AP-FILIAL | Port 0 | Straight-Through |

**Telefone IP (opcional):** o 7960 precisa de energia. Clique nele → aba **Physical** → arraste o **IP_PHONE_POWER_ADAPTER** (lista à esquerda) até a tomada do telefone (canto inferior direito da imagem).

**Cores dos pontos nos cabos:** é normal os pontos ficarem **vermelhos** nas portas dos roteadores até você rodar `no shutdown` (os comandos do passo 5 já fazem isso). Nos switches, eles ficam **laranja** por uns 30 segundos (Spanning Tree) e depois ficam **verdes**.

---

## 5. Configurar switches e roteadores (colar os comandos)

**Ordem recomendada:** SW-DIST1 → SW-DIST2 → SW-CORE → SW-FILIAL → R-ISP → R-MATRIZ → R-FILIAL.

Para cada equipamento:

1. Abra o arquivo correspondente em [`configs/`](configs/) (por exemplo, `SW-DIST1.txt`) no Bloco de Notas ou no VS Code e copie **todo o conteúdo** (Ctrl+A, Ctrl+C).
2. No Packet Tracer, **clique no equipamento** → aba **CLI**.
3. Se aparecer a pergunta
   `Would you like to enter the initial configuration dialog? [yes/no]:`
   digite `no` e aperte Enter. Aperte Enter de novo até aparecer o prompt `Router>` ou `Switch>`.
4. Clique dentro da área preta e cole com **Ctrl+V** (ou clique com o botão direito → *Paste*). O arquivo já começa com `enable` (entra no modo privilegiado, prompt `#`) e `configure terminal` (entra no modo de configuração, prompt `(config)#`), e termina com `end` e `write memory` (salva a configuração na NVRAM).
5. Espere terminar e confira que o prompt mudou para o nome certo (por exemplo, `SW-DIST1#`).

Linhas que começam com `!` são comentários: o IOS as ignora.

Se o PT travar ao colar o arquivo inteiro, cole **um bloco por vez** (de um comentário `! ----------` até o próximo).

### Conferências após colar

No modo `#` de cada equipamento, rode (pode usar Tab para completar):

| Equipamento | Comando | O que deve aparecer |
|---|---|---|
| Switches | `show vlan brief` | VLANs 10, 20, 30, 40, 50, 60, 99, 999 (filial: 99, 110, 120, 150, 999) com as portas certas |
| Switches | `show interfaces trunk` | Portas de uplink em modo *trunking*, native vlan 99 |
| Roteadores | `show ip interface brief` | Subinterfaces e WAN com Status **up** e Protocol **up** |
| Roteadores | `show ip route` | Redes `C` (conectadas) e `S` (estáticas) da outra unidade |

---

## 6. Configurar os servidores

Siga o arquivo [`configs/SRV-INFRA.md`](configs/SRV-INFRA.md). Resumo:

1. Em cada servidor: **Desktop → IP Configuration → Static** e preencha IP, máscara, gateway 192.168.30.1 e DNS 192.168.30.11.
2. **SRV-DHCP:** Services → DHCP → On → edite o `serverPool` e adicione os outros 8 pools.
3. **SRV-DNS:** Services → DNS → On → 5 registros A + 1 CNAME.
4. **SRV-WEB:** Services → HTTP → edite o `index.html`.
5. **SRV-FTP:** Services → FTP → crie o usuário `agrotech` / `agrotech123`.

---

## 7. Configurar o Wi-Fi de visitantes

### 7.1 Access Points

**AP-VISITANTES** (matriz): clique nele → aba **Config** → no menu à esquerda, **Port 1** (a porta sem fio):

- **SSID:** `AgroTech-Visitantes`
- **Authentication:** marque **WPA2-PSK**
- **PSK Pass Phrase:** `Visitante2026`

**AP-FILIAL** (filial): igual, mas com **SSID** `AgroTech-Visitantes-Filial` e a mesma senha.

### 7.2 Placa sem fio nos laptops

O Laptop-PT vem com placa de rede cabeada. Para trocar:

1. Clique no **Laptop-Visitante** → aba **Physical**.
2. Clique no **botão de energia** da imagem do laptop para **desligá-lo** (a luz verde apaga).
3. Arraste a placa que está encaixada no laptop (**PT-LAPTOP-NM-1CFE**) de volta para a lista de módulos à esquerda.
4. Na lista, clique em **WPC300N** e arraste-o para o encaixe vazio do laptop.
5. Ligue o laptop de novo no botão de energia.
6. Aba **Config** → **Wireless0** → **SSID** `AgroTech-Visitantes`, **Authentication** WPA2-PSK, **PSK Pass Phrase** `Visitante2026`. Na mesma tela, em **IP Configuration**, marque **DHCP**.

Repita para o **Laptop-Visitante-Filial** com o SSID `AgroTech-Visitantes-Filial`.

Quando conectar, aparece uma linha tracejada (ondas) entre o laptop e o AP.

---

## 8. Colocar os PCs em DHCP

Para **PC-ADM, PC-COM, PC-TI, PC-CAM, PC-FILIAL-ADM e PC-FILIAL-OFI**: clique no PC → aba **Desktop** → **IP Configuration** → marque **DHCP**.

A mensagem `DHCP request successful.` deve aparecer em alguns segundos, com o IP preenchido. Se aparecer `DHCP failed. APIPA is being used` (IP 169.254.x.x), veja [Se der errado](#11-se-der-errado).

IPs esperados (o primeiro de cada pool costuma ser o `.100`):

| Dispositivo | VLAN | IP esperado | Gateway |
|---|---|---|---|
| PC-ADM | 10 | 192.168.10.100 | 192.168.10.1 |
| PC-COM | 20 | 192.168.20.100 | 192.168.20.1 |
| PC-TI | 30 | 192.168.30.100 | 192.168.30.1 |
| PC-CAM | 40 | 192.168.40.100 | 192.168.40.1 |
| Laptop-Visitante | 50 | 192.168.50.100 | 192.168.50.1 |
| IP-PHONE | 60 | 192.168.60.100 | 192.168.60.1 |
| PC-FILIAL-ADM | 110 | 192.168.110.100 | 192.168.110.1 |
| PC-FILIAL-OFI | 120 | 192.168.120.100 | 192.168.120.1 |
| Laptop-Visitante-Filial | 150 | 192.168.150.100 | 192.168.150.1 |

Confira o IP real de cada um com `ipconfig` antes dos testes (se a ordem de pedidos for diferente, pode vir `.101`).

---

## 9. Executar os testes

Os testes de linha de comando são feitos em **Desktop → Command Prompt**. O teste de navegador fica em **Desktop → Web Browser**.

> O **primeiro ping** entre redes diferentes às vezes perde 1 ou 2 pacotes (o ARP ainda está sendo resolvido). Rode de novo: o segundo deve dar 4/4.

| # | Onde | Comando / ação | Resultado esperado | Prova |
|---|---|---|---|---|
| T1 | PC-ADM | `ipconfig /all` | IP 192.168.10.1xx, Gateway 192.168.10.1, DNS 192.168.30.11 | DHCP com relay funcionando |
| T2 | PC-ADM | `ipconfig /release` e depois `ipconfig /renew` | Recebe IP de novo | DHCP sob demanda |
| T3 | PC-TI | `ping 192.168.30.10` | Reply (4/4) | Ping **intra-VLAN** (VLAN 30) |
| T4 | PC-ADM | `ping 192.168.20.100` (PC-COM) | Reply | Ping **inter-VLAN** (roteamento no R-MATRIZ) |
| T5 | PC-ADM | `ping 192.168.30.12` | Reply | Inter-VLAN até o servidor Web |
| T6 | PC-ADM | `ping 192.168.110.100` (PC-FILIAL-ADM) | Reply | Matriz → filial |
| T7 | PC-FILIAL-ADM | `ping 192.168.10.100` | Reply | Filial → matriz |
| T8 | PC-ADM | `tracert 192.168.110.100` | Saltos 192.168.10.1 → 203.0.113.2 → 198.51.100.2 → destino | Caminho pela WAN |
| T9 | PC-ADM | `nslookup intranet.agrotech.local` | Address 192.168.30.12 | DNS |
| T10 | PC-ADM | Web Browser → `http://intranet.agrotech.local` → Go | Página "AgroTech - Intranet" | DNS + HTTP |
| T11 | PC-FILIAL-ADM | Web Browser → `http://erp.agrotech.local` | Mesma página (CNAME) | DNS/HTTP da filial pela WAN |
| T12 | PC-TI | `ftp 192.168.30.13` (usuário `agrotech`, senha `agrotech123`), depois `dir` e `quit` | Login OK e lista de arquivos | FTP |
| T13 | PC-ADM | `ping 8.8.8.8` | Reply | Saída para a "Internet" |
| T14 | Laptop-Visitante | `ipconfig` | IP 192.168.50.1xx | DHCP passa pela ACL |
| T15 | Laptop-Visitante | `ping 8.8.8.8` | Reply | Visitante navega na Internet |
| T16 | Laptop-Visitante | `ping 192.168.10.100` e `ping 192.168.30.12` | **Destination host unreachable** / Request timed out | **ACL bloqueando** as redes internas |
| T17 | Laptop-Visitante-Filial | `ping 8.8.8.8` e `ping 192.168.110.100` | 8.8.8.8 responde; 192.168.110.100 é bloqueado | ACL da filial |
| T18 | R-MATRIZ (CLI) | `show access-lists` | Contadores `(xx matches)` na linha `deny` | A ACL realmente filtrou |

No T16, o visitante ainda consegue **resolver** nomes (a ACL libera só a porta 53 até o DNS interno), mas não consegue **abrir** a intranet nem pingar nada interno. Isso é proposital: é o comportamento de uma rede de convidados.

### Opcional: ver o DORA acontecendo (modo Simulação)

1. No canto inferior direito, clique em **Simulation** (ao lado de *Realtime*).
2. Em **Edit Filters**, deixe marcado só **DHCP**.
3. No PC-COM: Desktop → IP Configuration → marque **Static** e depois **DHCP** de novo.
4. Clique em **Play** (▶) e veja os envelopes DHCP indo do PC até o SRV-DHCP, passando pelo R-MATRIZ (relay). Clique num envelope para ver as camadas do pacote.
5. Volte para **Realtime** ao terminar.

### Opcional: túnel GRE

Depois que tudo funcionar, veja [`configs/GRE-OPCIONAL.txt`](configs/GRE-OPCIONAL.txt) para demonstrar um túnel entre matriz e filial (o mesmo princípio da VPN do projeto real).

---

## 10. Tirar os prints e salvar o arquivo

### Como tirar um print no Windows

1. Aperte **Win + Shift + S** e selecione a área com o mouse.
2. Clique na notificação "Captura copiada para a área de transferência" que aparece no canto da tela (abre a Ferramenta de Captura).
3. Aperte **Ctrl + S** e salve em `agrotech-infraestrutura-redes\evidencias\prints\` com o nome da tabela abaixo (formato PNG).

### Prints do Packet Tracer

| Arquivo | O que mostrar |
|---|---|
| `pt-01-topologia.png` | A topologia inteira, com todos os links verdes |
| `pt-02-ipconfig-pc-adm.png` | T1: `ipconfig /all` no PC-ADM |
| `pt-03-ping-intra-vlan.png` | T3: PC-TI pingando 192.168.30.10 |
| `pt-04-ping-inter-vlan.png` | T4: PC-ADM pingando o PC-COM |
| `pt-05-ping-matriz-filial.png` | T6 + T8: ping e tracert do PC-ADM até a filial |
| `pt-06-nslookup.png` | T9: nslookup da intranet |
| `pt-07-navegador-intranet.png` | T10: navegador do PC-ADM com a intranet aberta |
| `pt-08-ftp.png` | T12: sessão FTP no PC-TI |
| `pt-09-visitante-bloqueado.png` | T15 + T16: Laptop-Visitante (8.8.8.8 ok, rede interna bloqueada) |
| `pt-10-show-access-lists.png` | T18: `show access-lists` no R-MATRIZ |
| `pt-11-show-vlan-brief.png` | `show vlan brief` no SW-DIST1 |
| `pt-12-show-ip-route.png` | `show ip route` no R-MATRIZ |
| `pt-13-dhcp-pools.png` | Aba Services → DHCP do SRV-DHCP com os pools |
| `pt-14-dns-registros.png` | Aba Services → DNS do SRV-DNS com os registros |

### Salvar o arquivo .pkt

Menu **File → Save As** → navegue até a pasta `agrotech-infraestrutura-redes\packet-tracer\` → nome `agrotech` → **Salvar**. O arquivo fica `packet-tracer/agrotech.pkt`.

Salve também de vez em quando durante a montagem (Ctrl+S): o Packet Tracer pode fechar sozinho.

---

## 11. Se der errado

| Sintoma | Causa provável | Solução |
|---|---|---|
| Ponto **vermelho** na porta do roteador | Interface desligada (padrão nos roteadores) | Na CLI: `configure terminal` → `interface gi0/0` → `no shutdown`. Confira se colou o arquivo inteiro |
| Ponto vermelho num cabo entre dois switches ou dois roteadores | Tipo de cabo errado | Apague o cabo (ícone **X** na barra da direita, ou tecla Delete) e use **Cross-Over** |
| Ponto **laranja** que não fica verde | Spanning Tree ainda bloqueando, ou BPDU Guard desligou a porta | Espere 30 s. Se continuar, `show interfaces status` e veja se a porta está `err-disabled`; nesse caso: `interface fa0/X` → `shutdown` → `no shutdown` |
| `show interfaces trunk` vazio | Porta errada no cabo, ou o arquivo do switch não foi colado | Confira a tabela de cabos; o uplink precisa ser exatamente a porta indicada |
| PC fica com **169.254.x.x** (DHCP falhou) | Relay ou pool faltando | 1) `show running-config` no roteador e confira o `ip helper-address 192.168.30.10` na subinterface da VLAN; 2) confira se o SRV-DHCP tem o **gateway 192.168.30.1**; 3) confira se o pool da VLAN existe com o gateway certo; 4) clique em Static e depois em DHCP de novo |
| Ping inter-VLAN falha, mas intra-VLAN funciona | Subinterface ou trunk com problema | `show ip interface brief` no R-MATRIZ (subinterfaces up/up?) e `show interfaces trunk` no SW-CORE (VLAN liberada?) |
| Ping matriz ↔ filial falha | Rota faltando ou WAN desligada | `show ip route` nos três roteadores: R-MATRIZ precisa das redes 192.168.110/120/150; R-FILIAL das 192.168.10–60; R-ISP de todas. `ping 203.0.113.2` a partir do R-MATRIZ testa a WAN |
| Navegador mostra "Host Name Unresolved" | DNS errado no PC ou registro faltando | `ipconfig /all` deve mostrar DNS 192.168.30.11; confira se o SRV-DNS está On e se o nome foi digitado sem erro |
| Navegador abre pelo IP mas não pelo nome | Mesmo caso acima | Teste `nslookup intranet.agrotech.local` |
| Visitante não recebe IP | ACL sem a linha do DHCP, ou Wi-Fi não conectado | `show access-lists` deve começar com `permit udp any any eq bootps`; confira SSID/senha no laptop |
| Visitante consegue pingar a rede interna | ACL não aplicada | `show running-config interface gi0/0.50` deve ter `ip access-group VISITANTES-MATRIZ in` |
| `% Invalid input detected at '^' marker` | Comando não suportado nessa versão do PT, ou colado no modo errado | Veja em qual linha parou; se for `encapsulation dot1Q 99 native`, pode ignorar (a VLAN 99 é só a nativa). Para as outras, confira se o prompt estava em `(config)#` |
| A CLI pede `Password:` | É a senha de *enable* | `AgroTech2026` |
