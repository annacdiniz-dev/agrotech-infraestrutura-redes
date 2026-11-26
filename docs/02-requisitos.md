# 2. Requisitos da rede

Este documento detalha o levantamento de necessidades de conectividade e comunicação da AgroTech, organizado segundo a abordagem *top-down* de projeto de redes (OPPENHEIMER, 1999): desempenho, funcionalidade, disponibilidade, escalabilidade, segurança e gerenciamento.

## 2.1 Inventário de dispositivos

A contagem abaixo foi feita setor por setor e serve de base para o dimensionamento dos switches, das sub-redes e dos pools DHCP. Os telefones IP compartilham o mesmo ponto de rede do computador (o telefone tem um switch interno e separa o tráfego de voz pela VLAN de voz), o que reduz o número de pontos de cabeamento.

### Matriz (Goiânia)

| Setor | VLAN | PCs | Impressoras | Telefones IP | Outros | Pontos de rede |
|---|---|---|---|---|---|---|
| Recepção | 20 | 2 | 1 | 2 | — | 3 |
| Administração | 10 | 4 | 1 | 4 | — | 5 |
| Financeiro | 10 | 4 | — | 4 | — | 4 |
| Comercial | 20 | 5 | 1 | 5 | — | 6 |
| RH | 20 | 2 | — | 2 | — | 2 |
| Sala de Reuniões | 20 | 1 | — | 1 | 1 TV/sistema de vídeo | 2 |
| TI | 30 | 2 | — | 2 | — | 2 |
| Oficina Técnica | 20 | 3 | 1 | 1 | — | 4 |
| Estoque | 20 | 2 | 1 | — | — | 3 |
| Servidores / rack | 30 / 40 | — | — | — | 1 servidor de infraestrutura, 1 NAS, 1 NVR | 3 |
| Câmeras IP | 40 | — | — | — | 8 câmeras | 8 |
| Access Points | 20 / 50 | — | — | — | 5 APs | 5 |
| **Subtotal** | | **25** | **5** | **21** | **17** | **47** |

### Filial (Anápolis)

| Setor | VLAN | PCs | Impressoras | Telefones IP | Outros | Pontos de rede |
|---|---|---|---|---|---|---|
| Atendimento | 110 | 3 | 1 | 2 | — | 4 |
| Escritório Administrativo | 110 | 3 | 1 | 3 | — | 4 |
| Oficina Técnica | 120 | 3 | 1 | 1 | — | 4 |
| Estoque | 120 | 1 | — | — | — | 1 |
| Access Points | 110 / 150 | — | — | — | 3 APs | 3 |
| **Subtotal** | | **10** | **3** | **6** | **3** | **16** |

### Total

| Categoria | Quantidade |
|---|---|
| Dispositivos cabeados (PCs, impressoras, telefones, câmeras, servidores, APs, TV): 68 na matriz + 22 na filial | 90 |
| Dispositivos móveis corporativos no Wi-Fi (notebooks e celulares de técnicos e vendedores) | cerca de 15 |
| Visitantes simultâneos no Wi-Fi (estimativa) | 10 a 20 |
| **Total em uso simultâneo** | **cerca de 100 dispositivos corporativos + visitantes** |
| **Meta de expansão** | **150 dispositivos** |

## 2.2 Desempenho

| Requisito | Especificação | Justificativa |
|---|---|---|
| Rede cabeada | Gigabit Ethernet (1000BASE-T), cabeamento UTP Cat6 | Transferência de arquivos e acesso ao ERP sem gargalo |
| Rede sem fio | Wi-Fi 6 (IEEE 802.11ax), até 1.800 Mbps por AP | Densidade de dispositivos móveis e baixa latência |
| Internet | Link dedicado de fibra de 1 Gbps (Vivo Empresas) | Videoconferência, sistemas em nuvem, VPN com a filial |
| Latência para VoIP | Até 150 ms ponta a ponta, *jitter* abaixo de 30 ms | Recomendação ITU-T G.114 para voz com boa qualidade |
| Priorização | QoS com a VLAN 60 (VoIP) em fila prioritária | Voz não pode competir com downloads |

## 2.3 Funcionalidade

A rede deve oferecer:

- comunicação e compartilhamento de dados entre matriz e filial;
- acesso ao ERP (`erp.agrotech.local`) a partir das duas unidades;
- intranet corporativa (`intranet.agrotech.local`);
- servidor de arquivos (`ftp.agrotech.local`);
- configuração automática de IP (DHCP) e resolução de nomes internos (DNS);
- impressão em rede nos setores;
- monitoramento por câmeras IP com gravação no NVR;
- telefonia IP;
- Wi-Fi 6 corporativo e Wi-Fi isolado para visitantes.

## 2.4 Disponibilidade

| Requisito | Como é atendido |
|---|---|
| Equipamentos com MTBF elevado | Switches e APs de linha empresarial (Cisco Business, TP-Link JetStream/Omada) |
| MTTR baixo | Topologia em estrela (falha isolada a um ponto), portas reservas nos switches, configurações versionadas neste repositório |
| Energia | Nobreak (UPS) de 1400 VA no rack da matriz e no rack da filial |
| Backup das configurações | Cópia periódica das configurações dos switches/firewall e dos arquivos `docker/` no Git |
| Backup dos dados | Backup diário automatizado do servidor para o NAS da sala de Servidores |
| Recuperação rápida dos serviços | Serviços em containers: `docker compose up -d` recria DHCP, DNS, Web e FTP em segundos |

## 2.5 Escalabilidade

- Meta: crescer de cerca de 100 para **150 dispositivos** sem alterações estruturais.
- Cada VLAN usa uma sub-rede **/24** (254 endereços úteis). Mesmo a maior VLAN (20) usa menos de 30 endereços hoje.
- Cada pool DHCP tem 101 endereços (`.100` a `.200`), o que comporta sozinho a meta de 150 dispositivos distribuída entre as VLANs.
- Os switches ficam com portas livres para expansão (ver [ocupação de portas](03-planejamento-infra.md#35-ocupação-de-portas-dos-switches)).
- O plano reserva as VLANs 140 (câmeras da filial) e 160 (VoIP da filial) para a próxima fase.

## 2.6 Segurança

| Medida | Implementação |
|---|---|
| Firewall corporativo | pfSense na matriz e na filial, com filtragem de pacotes e inspeção de estado (*stateful*) |
| Segmentação | Uma VLAN por grupo de setores; tráfego entre VLANs passa obrigatoriamente pelo firewall |
| Rede de visitantes isolada | VLANs 50 e 150: somente Internet. Demonstrado com ACL no Packet Tracer |
| Câmeras isoladas | VLAN 40 acessível apenas pelo NVR e pela TI |
| Controle de acesso | 802.1X no Wi-Fi corporativo; portas de switch sem uso desligadas e na VLAN 999 |
| Proteção do Spanning Tree | BPDU Guard e PortFast nas portas de acesso |
| Comunicação entre unidades | VPN IPSec Site-to-Site (criptografia do tráfego pela Internet) |
| Acesso administrativo | Senhas de *enable* criptografadas, banner de aviso, gerência pela VLAN 30 |
| Backup | Diário e automatizado |

## 2.7 Gerenciamento

- Monitoramento centralizado com protocolo **SNMP** (os switches Cisco CBS350 e TP-Link JetStream são gerenciáveis), usando uma ferramenta como Zabbix ou LibreNMS em um container no servidor de infraestrutura.
- Todos os equipamentos de rede têm IP de gerência na VLAN 30 (ver [plano de IP](04-plano-ip.md)).
- APs gerenciados centralmente pelo Omada Controller.
- Configurações dos serviços versionadas no Git (este repositório), o que permite auditoria e reconstrução rápida.

## 2.8 Matriz de comunicação entre segmentos

O quadro resume quem pode iniciar conexão com quem. É a base das regras de firewall.

| Origem ↓ / Destino → | Servidores (V30) | ERP/Intranet | Impressoras | Câmeras (V40) | Internet | Filial |
|---|---|---|---|---|---|---|
| Adm./Financeiro (V10) | DNS, DHCP, FTP | Sim | Sim | Não | Sim | Sim |
| Comercial/RH/Recepção (V20) | DNS, DHCP, FTP | Sim | Sim | Não | Sim | Sim |
| TI (V30) | Total | Sim | Sim | Sim (gerência) | Sim | Sim |
| Câmeras (V40) | Somente NVR | Não | Não | — | Não | Não |
| Visitantes (V50/V150) | Somente DNS | Não | Não | Não | **Sim** | Não |
| VoIP (V60) | PABX IP | Não | Não | Não | Operadora SIP | Sim (ramais) |
| Filial (V110/V120) | DNS, DHCP, FTP | Sim | Sim | Não | Sim | — |
