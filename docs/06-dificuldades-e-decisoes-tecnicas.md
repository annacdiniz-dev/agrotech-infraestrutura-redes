# 6. Dificuldades e decisões técnicas

> Atende ao item "**Explicação das soluções adotadas**" (requisito 5 — Documentação e evidências) e ao ponto da apresentação "**As principais dificuldades e decisões técnicas do projeto**".

## 6.1 Limitações e decisões técnicas do ambiente Docker

### DHCP no Docker Desktop (Windows) só funciona entre containers

**Dificuldade.** No Windows, o Docker Desktop roda os containers dentro de uma máquina virtual Linux (WSL 2). As redes *bridge* existem **dentro dessa VM**, sem ligação de camada 2 com a placa de rede física do computador. Como o DHCP depende de **broadcast** (o cliente ainda não tem IP e grita "alguém me dá um endereço?" para 255.255.255.255), um notebook ligado na mesma rede Wi-Fi do PC nunca alcançaria o nosso servidor DHCP. O driver **macvlan**, que daria aos containers um endereço direto na rede física, também não funciona no Docker Desktop para Windows: ele fica preso dentro da VM.

**Decisão.** A demonstração do DHCP é feita **entre containers**, na rede `agrotech-lan`, que reproduz a VLAN 30. Um container cliente (`agrotech-cliente`) faz o papel do PC de um funcionário e passa pelo processo DORA completo. Essa limitação não afeta DNS, Web e FTP, que usam unicast e são acessíveis também pelo Windows (a intranet abre em `http://localhost:8080`).

**Como seria em produção.** O servidor DHCP ficaria no servidor de infraestrutura da VLAN 30 (Linux + Docker com rede macvlan, ou o serviço instalado direto no sistema) e atenderia **todas as VLANs** com um pool por rede. Os pedidos das outras VLANs chegariam pelo **DHCP Relay** do firewall (`ip helper-address` no Cisco; *DHCP Relay* no pfSense). É exatamente esse cenário que demonstramos no Packet Tracer.

### O `/etc/resolv.conf` do container não podia ser substituído

**Dificuldade.** No primeiro teste, o cliente recebeu o IP do DHCP, mas o script padrão do `udhcpc` falhou ao gravar o DNS (`mv: can't rename '/etc/resolv.conf.21': Resource busy`). O Docker monta esse arquivo dentro do container, e um arquivo montado não pode ser trocado com `mv`.

**Decisão.** Criamos o [`docker/cliente/udhcpc.script`](../docker/cliente/udhcpc.script), que reescreve o arquivo no lugar (`>`) em vez de substituí-lo. Com isso, o cliente passou a usar o DNS entregue pelo DHCP, e os testes por nome (`curl http://intranet.agrotech.local`) funcionaram ponta a ponta.

### O cliente precisava repetir o DHCPDISCOVER

**Dificuldade.** Nos primeiros testes, o log mostrava `DISCOVER → OFFER → DISCOVER → OFFER → REQUEST → ACK`: o cliente não aceitava a primeira oferta e repetia o pedido 3 segundos depois. Por padrão, o dnsmasq responde em *unicast* a um cliente que ainda não tem IP, e essa primeira resposta não era aceita pelo cliente dentro da bridge do Docker.

**Decisão.** Adicionamos `dhcp-broadcast` ao [`dnsmasq.conf` do DHCP](../docker/dhcp/dnsmasq.conf), fazendo o servidor responder em broadcast (que é o comportamento clássico descrito na RFC 2131 para clientes sem IP). O DORA passou a acontecer em uma única rodada, com as 4 mensagens.

### Por que dnsmasq

| Alternativa | Avaliação |
|---|---|
| **dnsmasq** (escolhido) | Leve (imagem Alpine de poucos MB), faz DHCP e DNS, configuração em poucas linhas, logs claros do DORA (`log-dhcp`) e das consultas (`log-queries`). Ideal para uma rede de médio porte e para fins didáticos. |
| ISC Kea (DHCP) + BIND 9 (DNS) | Padrões de mercado para grandes redes, mas com configuração bem mais extensa (JSON no Kea, arquivos de zona no BIND). Seriam a evolução natural se a AgroTech crescer muito. |
| ISC DHCP Server (`isc-dhcp-server`) | Descontinuado pelo ISC desde 2022. |

Usamos a **mesma imagem base (dnsmasq) em dois containers separados**: um com `port=0` (só DHCP) e outro com `no-dhcp-interface` (só DNS). Cada serviço tem seu IP (.10 e .11), como no plano de endereçamento, e uma falha ou mudança em um não afeta o outro.

### Conflito entre o IPAM do Docker e o pool DHCP

O Docker distribui IPs automaticamente aos containers sem IP fixo. Se ele escolhesse, por exemplo, 192.168.30.150, poderia colidir com um endereço entregue pelo nosso DHCP. A opção `ip_range: 192.168.30.0/28` limita o Docker aos endereços .1 a .14, longe do pool (.100 a .200).

### FTP: incluído porque funcionou de forma estável

O FTP usa duas conexões (controle na porta 21 e dados numa porta extra). Entre containers, o modo passivo funcionou sem ajustes, e o serviço passou em todos os testes (listar, baixar, enviar, recusar senha errada). Por isso foi mantido como serviço bônus. **Limitação:** o FTP não foi publicado para o Windows (`localhost:21`), porque o modo passivo informaria ao cliente o IP interno do container (192.168.30.13), que o Windows não alcança. Para isso seria preciso publicar as portas 21100–21110 e configurar `pasv_address`. Em produção, a recomendação é **SFTP** (FTP sobre SSH, criptografado) ou FTPS, já que o FTP envia a senha em texto puro.

### Fins de linha e codificação no Windows

Arquivos de configuração montados em containers Linux não podem ter fim de linha Windows (CRLF), senão o dnsmasq e o shell leem caracteres extras. O [`.gitattributes`](../.gitattributes) força LF em todos os arquivos (e CRLF só nos scripts `.ps1`), mesmo que o repositório seja clonado no Windows. Os scripts PowerShell gravam as evidências em UTF-8 explicitamente, porque o Windows PowerShell 5.1 usaria UTF-16 por padrão.

## 6.2 Decisões da infraestrutura

### Router-on-a-stick em vez de switch camada 3

| | Router-on-a-stick (escolhido) | Switch camada 3 |
|---|---|---|
| Onde é feito o roteamento entre VLANs | No firewall/roteador, por subinterfaces 802.1Q | No próprio switch core (SVIs) |
| Segurança | **Todo** tráfego entre setores passa pelo firewall e pode ser filtrado | Tráfego entre VLANs não passa pelo firewall, a menos que se configure ACL no switch |
| Desempenho | Limitado ao link do trunk (1 Gbps compartilhado) | Roteamento em hardware, na velocidade do switch |
| Custo | Usa o pfSense que já seria comprado | Exige switch L3 (mais caro) |

Para uma empresa de cerca de 100 dispositivos, com a maior parte do tráfego indo para a Internet e para os servidores, 1 Gbps é suficiente. O ganho de segurança (filtragem centralizada no pfSense, inclusive entre setores) pesou mais. Se o tráfego interno crescer, a evolução é trocar o core por um switch L3 e manter o pfSense na borda.

### Rotas estáticas em vez de roteamento dinâmico

São apenas 3 roteadores e 9 redes internas. Rotas estáticas são simples, previsíveis e não geram tráfego de protocolo. Com mais filiais, o caminho seria OSPF sobre os túneis VPN.

### VPN Site-to-Site documentada e não simulada

O projeto real interliga matriz e filial por **VPN IPSec Site-to-Site entre os dois pfSense**. O Packet Tracer não tem pfSense e a simulação de IPSec nos roteadores ISR exige licença de segurança e uma configuração que fugiria do equipamento real. Optamos por:

1. **Simular a conectividade** com rotas estáticas passando pelo R-ISP. Observação: na Internet real, um provedor não roteia IPs privados; é justamente por isso que a VPN existe.
2. **Demonstrar o conceito de túnel** com um túnel GRE opcional ([`GRE-OPCIONAL.txt`](../packet-tracer/configs/GRE-OPCIONAL.txt)): com ele, o R-ISP deixa de precisar conhecer as redes privadas. O GRE encapsula mas **não criptografa**; o IPSec faz as duas coisas.
3. **Documentar a configuração do pfSense** (abaixo).

**Configuração prevista da VPN IPSec no pfSense** (*VPN → IPsec*):

| Parâmetro | Matriz (Goiânia) | Filial (Anápolis) |
|---|---|---|
| Fase 1 — versão | IKEv2 | IKEv2 |
| Gateway remoto | IP público da filial | IP público da matriz |
| Autenticação | Chave pré-compartilhada (PSK) longa e aleatória | A mesma PSK |
| Criptografia / integridade / DH | AES-256-GCM / SHA-256 / grupo 14 | Idem |
| Fase 2 — redes locais | 192.168.10.0/24, 192.168.20.0/24, 192.168.30.0/24, 192.168.60.0/24 | 192.168.110.0/24, 192.168.120.0/24 |
| Fase 2 — redes remotas | 192.168.110.0/24, 192.168.120.0/24 | 192.168.10.0/24, 192.168.20.0/24, 192.168.30.0/24, 192.168.60.0/24 |
| Protocolo | ESP, AES-256-GCM, PFS grupo 14 | Idem |
| Regras de firewall (aba IPsec) | Liberar da filial para ERP, DNS, DHCP Relay, FTP e VoIP | Liberar da matriz para as redes da filial |

As VLANs de visitantes (50, 150) e de câmeras (40) **não** entram na VPN.

### Um servidor por serviço no Packet Tracer

O plano entrega o DNS 192.168.30.11 aos clientes e aponta `intranet` para .12 e `ftp` para .13. No Packet Tracer cada Server-PT tem um IP, então usamos 4 servidores (SRV-DHCP, SRV-DNS, SRV-WEB, SRV-FTP), cada um com o mesmo IP do container equivalente. Assim, o plano de IP é **idêntico** no Docker e no Packet Tracer.

### ACL de visitantes

A ACL é **estendida** e foi aplicada na **entrada da subinterface dos visitantes** (Gi0/0.50 e Gi0/0.150), ou seja, o mais perto possível da origem do tráfego, como se recomenda para ACLs estendidas. Ela permite, nesta ordem: DHCP (senão o visitante nem recebe IP), consulta DNS ao servidor interno (porta 53, para resolver nomes de sites), bloqueia todas as redes 192.168.0.0/16 e libera o resto (Internet). O visitante consegue **resolver** o nome da intranet, mas não consegue **acessá-la**.

### VLAN nativa 99 e VLAN 999 para portas sem uso

Os trunks usam a VLAN nativa 99, sem nenhum host, em vez da VLAN 1 padrão, o que reduz o risco de ataques de *VLAN hopping*. Portas sem uso ficam desligadas (`shutdown`) e na VLAN 999, que não é roteada: quem plugar um cabo numa porta livre não entra em nenhuma rede.

### Senhas de laboratório no repositório

As senhas de *enable* (`AgroTech2026`) e do FTP (`agrotech123`) estão em texto nos arquivos, porque o repositório precisa permitir a reprodução da solução. **Em produção**, as senhas ficariam fora do Git (arquivo `.env` não versionado ou cofre de senhas), e o acesso administrativo seria por SSH com usuários individuais.

## 6.3 Melhorias futuras

- Publicar o serviço de DHCP para todas as VLANs no servidor real (macvlan + `dhcp-range` por VLAN).
- Trocar FTP por SFTP.
- Adicionar Omada Controller e Zabbix/LibreNMS (monitoramento SNMP) como containers no mesmo servidor.
- Implantar as VLANs reservadas da filial (140 câmeras, 160 VoIP).
- Link de Internet secundário (outra operadora) com failover no pfSense, para eliminar o ponto único de falha.
- Switch core camada 3 se o tráfego entre VLANs crescer.
