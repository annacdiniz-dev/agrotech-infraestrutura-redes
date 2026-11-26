# 1. Caracterização da empresa e levantamento de requisitos

> **Itens do enunciado atendidos neste documento** (requisito obrigatório 1 — critério "Caracterização da empresa e levantamento de requisitos", 1,0 pt)
>
> | Item pedido | Seção |
> |---|---|
> | Nome e segmento de atuação da empresa fictícia | [1.1](#11-identificação) |
> | Descrição das atividades desenvolvidas | [1.2](#12-atividades) |
> | Quantidade estimada de funcionários e setores | [1.3](#13-funcionários-e-setores) |
> | Levantamento das necessidades de conectividade e comunicação | [1.4](#14-levantamento-de-necessidades-de-conectividade-e-comunicação) e [1.5](#15-requisitos-da-rede) |

## 1.1 Identificação

| Item | Descrição |
|---|---|
| Razão social | AgroTech Soluções Agrícolas Ltda. (empresa fictícia) |
| Nome fantasia | AgroTech |
| Segmento | Agronegócio: comércio e serviços para máquinas agrícolas |
| Porte | Médio porte, cerca de 40 funcionários |
| Matriz | Goiânia – GO (edificação de aproximadamente 30 m × 18 m) |
| Filial | Anápolis – GO (edificação de aproximadamente 20 m × 10 m) |

## 1.2 Atividades

A AgroTech atua no comércio de máquinas agrícolas e na prestação de serviços técnicos para produtores rurais, cooperativas e empresas do setor agroindustrial. Seu portfólio compreende:

- venda de máquinas agrícolas;
- venda de peças e acessórios;
- assistência técnica especializada;
- manutenção preventiva e corretiva;
- consultoria técnica agrícola;
- atendimento corporativo a fazendas e cooperativas.

**Missão:** fornecer soluções tecnológicas e equipamentos agrícolas de qualidade, com suporte técnico eficiente, contribuindo para o desenvolvimento do agronegócio em Goiás.

**Mercado-alvo:** Goiânia, Anápolis e demais municípios do interior de Goiás.

## 1.3 Funcionários e setores

A empresa possui cerca de **40 funcionários**: 28 na matriz e 12 na filial.

### Matriz (Goiânia) — 28 funcionários

| Setor | Área aproximada | Funcionários | Principais atividades com uso de rede |
|---|---|---|---|
| Recepção | 5 m × 6 m | 2 | Atendimento a clientes, cadastro no ERP, telefonia |
| Administração | 5 m × 6 m | 4 | Gestão, contratos, ERP, e-mail, videoconferência |
| Financeiro | 5 m × 6 m | 4 | Contas a pagar/receber, faturamento, Internet Banking |
| Comercial | 5 m × 6 m | 5 | Vendas de máquinas e peças, propostas, CRM no ERP |
| RH | 5 m × 6 m | 2 | Folha de pagamento, documentos sigilosos de funcionários |
| Sala de Reuniões | 4 m × 7 m | — | Videoconferência com a filial e com clientes |
| TI + Sala de Equipamentos | 4 m × 7 m | 2 | Administração da rede, rack principal, suporte |
| Oficina Técnica | 5 m × 7 m | 6 | Ordens de serviço, consulta de manuais e catálogos técnicos |
| Servidores | 3 m × 3 m | — | Gravador de câmeras (NVR) e armazenamento de backup |
| Estoque | 4 m × 3 m | 3 | Entrada e saída de peças no ERP, etiquetas |

### Filial (Anápolis) — 12 funcionários

| Setor | Área aproximada | Funcionários | Principais atividades com uso de rede |
|---|---|---|---|
| Atendimento | 8 m × 6 m | 3 | Atendimento a clientes, vendas de balcão, ERP |
| Escritório Administrativo | 12 m × 6 m | 3 | Gestão local, financeiro da filial, ERP |
| Oficina Técnica | 10 m × 4,2 m | 4 | Ordens de serviço, manuais técnicos (FTP da matriz) |
| Estoque | 10 m × 4,2 m | 2 | Movimentação de peças no ERP |

As plantas baixas das duas unidades estão no [esquema físico](02-planejamento-da-infraestrutura.md#22-esquema-físico).

## 1.4 Levantamento de necessidades de conectividade e comunicação

O levantamento foi feito a partir das atividades de cada setor. As necessidades identificadas são:

| Necessidade | Quem precisa | Solução adotada no projeto |
|---|---|---|
| Acesso ao sistema de gestão (ERP) | Todos os setores, matriz e filial | Servidor de aplicação na matriz, acessível pela filial via VPN; nome `erp.agrotech.local` |
| Intranet corporativa | Todos os funcionários | Servidor Web (nginx) em `intranet.agrotech.local` |
| Compartilhamento de arquivos (manuais, catálogos, laudos) | Oficinas, Estoque, Comercial | Servidor FTP em `ftp.agrotech.local` |
| Configuração automática dos computadores | Todos os dispositivos clientes | Servidor DHCP central com relay (`ip helper-address`) |
| Resolução de nomes internos | Todos | Servidor DNS interno da zona `agrotech.local` |
| Impressão em rede | Recepção, Adm./Fin., Comercial/RH, Oficinas, Estoque | Impressoras com IP fixo nas VLANs de dados |
| Telefonia IP com baixa latência | Todos os setores | VLAN exclusiva de VoIP com prioridade (QoS) |
| Videoconferência | Administração, Sala de Reuniões | Link de 1 Gbps e QoS |
| Monitoramento por câmeras | Segurança patrimonial (matriz) | VLAN isolada de câmeras com NVR |
| Wi-Fi corporativo | Técnicos, vendedores, gestores | Wi-Fi 6 (TP-Link Omada EAP610) com autenticação 802.1X |
| Wi-Fi para clientes e visitantes | Recepção, Atendimento, Sala de Reuniões | Rede de visitantes separada, somente Internet |
| Comunicação segura matriz ↔ filial | Filial (ERP, arquivos, telefonia) | VPN IPSec Site-to-Site entre os firewalls pfSense |
| Acesso à Internet | Todos | Link dedicado de fibra de 1 Gbps (Vivo Empresas) em cada unidade |
| Proteção de dados sigilosos (RH, Financeiro) | RH, Financeiro | Segmentação por VLAN e regras de firewall |

O detalhamento técnico desses requisitos (desempenho, disponibilidade, segurança etc.) está na seção [1.5](#15-requisitos-da-rede).

---

## 1.5 Requisitos da rede

Este documento detalha o levantamento de necessidades de conectividade e comunicação da AgroTech, organizado segundo a abordagem *top-down* de projeto de redes (OPPENHEIMER, 1999): desempenho, funcionalidade, disponibilidade, escalabilidade, segurança e gerenciamento.

### 1.5.1 Inventário de dispositivos

A contagem abaixo foi feita setor por setor e serve de base para o dimensionamento dos switches, das sub-redes e dos pools DHCP. Os telefones IP compartilham o mesmo ponto de rede do computador (o telefone tem um switch interno e separa o tráfego de voz pela VLAN de voz), o que reduz o número de pontos de cabeamento.

#### Matriz (Goiânia)

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

#### Filial (Anápolis)

| Setor | VLAN | PCs | Impressoras | Telefones IP | Outros | Pontos de rede |
|---|---|---|---|---|---|---|
| Atendimento | 110 | 3 | 1 | 2 | — | 4 |
| Escritório Administrativo | 110 | 3 | 1 | 3 | — | 4 |
| Oficina Técnica | 120 | 3 | 1 | 1 | — | 4 |
| Estoque | 120 | 1 | — | — | — | 1 |
| Access Points | 110 / 150 | — | — | — | 3 APs | 3 |
| **Subtotal** | | **10** | **3** | **6** | **3** | **16** |

#### Total

| Categoria | Quantidade |
|---|---|
| Dispositivos cabeados (PCs, impressoras, telefones, câmeras, servidores, APs, TV): 68 na matriz + 22 na filial | 90 |
| Dispositivos móveis corporativos no Wi-Fi (notebooks e celulares de técnicos e vendedores) | cerca de 15 |
| Visitantes simultâneos no Wi-Fi (estimativa) | 10 a 20 |
| **Total em uso simultâneo** | **cerca de 100 dispositivos corporativos + visitantes** |
| **Meta de expansão** | **150 dispositivos** |

### 1.5.2 Desempenho

| Requisito | Especificação | Justificativa |
|---|---|---|
| Rede cabeada | Gigabit Ethernet (1000BASE-T), cabeamento UTP Cat6 | Transferência de arquivos e acesso ao ERP sem gargalo |
| Rede sem fio | Wi-Fi 6 (IEEE 802.11ax), até 1.800 Mbps por AP | Densidade de dispositivos móveis e baixa latência |
| Internet | Link dedicado de fibra de 1 Gbps (Vivo Empresas) | Videoconferência, sistemas em nuvem, VPN com a filial |
| Latência para VoIP | Até 150 ms ponta a ponta, *jitter* abaixo de 30 ms | Recomendação ITU-T G.114 para voz com boa qualidade |
| Priorização | QoS com a VLAN 60 (VoIP) em fila prioritária | Voz não pode competir com downloads |

### 1.5.3 Funcionalidade

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

### 1.5.4 Disponibilidade

| Requisito | Como é atendido |
|---|---|
| Equipamentos com MTBF elevado | Switches e APs de linha empresarial (Cisco Business, TP-Link JetStream/Omada) |
| MTTR baixo | Topologia em estrela (falha isolada a um ponto), portas reservas nos switches, configurações versionadas neste repositório |
| Energia | Nobreak (UPS) de 1400 VA no rack da matriz e no rack da filial |
| Backup das configurações | Cópia periódica das configurações dos switches/firewall e dos arquivos `docker/` no Git |
| Backup dos dados | Backup diário automatizado do servidor para o NAS da sala de Servidores |
| Recuperação rápida dos serviços | Serviços em containers: `docker compose up -d` recria DHCP, DNS, Web e FTP em segundos |

### 1.5.5 Escalabilidade

- Meta: crescer de cerca de 100 para **150 dispositivos** sem alterações estruturais.
- Cada VLAN usa uma sub-rede **/24** (254 endereços úteis). Mesmo a maior VLAN (20) usa menos de 30 endereços hoje.
- Cada pool DHCP tem 101 endereços (`.100` a `.200`), o que comporta sozinho a meta de 150 dispositivos distribuída entre as VLANs.
- Os switches ficam com portas livres para expansão (ver [ocupação de portas](02-planejamento-da-infraestrutura.md#25-ocupação-de-portas-dos-switches)).
- O plano reserva as VLANs 140 (câmeras da filial) e 160 (VoIP da filial) para a próxima fase.

### 1.5.6 Segurança

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

### 1.5.7 Gerenciamento

- Monitoramento centralizado com protocolo **SNMP** (os switches Cisco CBS350 e TP-Link JetStream são gerenciáveis), usando uma ferramenta como Zabbix ou LibreNMS em um container no servidor de infraestrutura.
- Todos os equipamentos de rede têm IP de gerência na VLAN 30 (ver [plano de IP](03-plano-de-enderecamento-ip.md)).
- APs gerenciados centralmente pelo Omada Controller.
- Configurações dos serviços versionadas no Git (este repositório), o que permite auditoria e reconstrução rápida.

### 1.5.8 Matriz de comunicação entre segmentos

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
