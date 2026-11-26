# 1. Caracterização da empresa

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

As plantas baixas das duas unidades estão no [esquema físico](03-planejamento-infra.md#32-esquema-físico).

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

O detalhamento técnico desses requisitos (desempenho, disponibilidade, segurança etc.) está em [02 — Requisitos](02-requisitos.md).
