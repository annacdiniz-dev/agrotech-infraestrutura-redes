# Roteiro da apresentação (8 a 10 minutos)

**Apresentadoras:** Anna Clara Diniz (AC) e Ana Júlia Francelin (AJ). O enunciado exige que **todos os integrantes participem e demonstrem conhecimento**; por isso as falas se alternam e cada uma apresenta uma parte de cada metade (planejamento e prática).

O enunciado pede que a apresentação explique **cinco pontos**. Cada bloco abaixo cobre um deles, na mesma ordem:

| Ponto exigido pelo enunciado | Bloco | Quem | Tempo |
|---|---|---|---|
| (abertura: empresa e necessidades) | 0 | AC | 1min |
| A estrutura da rede proposta | 1 | AJ | 2min |
| O plano de endereçamento IP e a segmentação | 2 | AC | 1min30 |
| Os serviços TCP/IP implementados | 3 | AJ | 1min30 |
| O funcionamento da solução utilizando Docker | 4 | AC | 2min |
| As principais dificuldades e decisões técnicas do projeto | 5 | AJ | 1min |

**Antes de começar (5 min antes):** Docker Desktop aberto e "Running"; rodar uma vez o `testar-tudo.ps1` (deixa as imagens prontas e evita esperar download na hora); Packet Tracer aberto com o `agrotech.pkt`; repositório aberto no GitHub; navegador em `http://localhost:8080`.

---

## Bloco 0 — Abertura: a empresa e as necessidades (AC, 1min)

**Mostrar:** README do repositório no GitHub.

- "Nosso projeto é a rede LAN corporativa da **AgroTech Soluções Agrícolas**, empresa fictícia de máquinas agrícolas, peças e assistência técnica, com **matriz em Goiânia e filial em Anápolis** e cerca de **40 funcionários** (28 + 12)."
- "Levantamos as necessidades de cada setor: ERP para todos, intranet, arquivos técnicos para as oficinas, impressão em rede, telefonia IP, câmeras, Wi-Fi corporativo e de visitantes."
- "Contamos cerca de **100 dispositivos** hoje e a meta é crescer até **150** sem refazer a rede."

## Bloco 1 — A estrutura da rede proposta (AJ, 2min)

**Mostrar:** `diagramas/fisico.png`, `diagramas/logico.png` e a topologia no Packet Tracer.

- "Fisicamente é uma **topologia em estrela** com cabo **UTP Cat6** e Gigabit. Todo ponto de rede vai até o **rack de 24U** na sala de TI; a filial tem um rack de 4U." (mostrar a planta e os racks)
- "Equipamentos: **firewall pfSense**, switch core **Cisco CBS350-48T**, switches de distribuição **TP-Link TL-SG3428**, access points **Wi-Fi 6**, um servidor para os serviços e nobreaks."
- "Logicamente, o firewall liga num **switch core**, que liga nos switches de distribuição. O roteamento entre os setores é **router-on-a-stick**: um cabo trunk até o firewall, com uma subinterface por VLAN. Assim todo tráfego entre setores passa pelo firewall." (mostrar o diagrama lógico)
- "Simulamos essa estrutura no **Packet Tracer**: matriz à esquerda, provedor no meio, filial à direita." (mostrar a topologia)

## Bloco 2 — O plano de endereçamento IP e a segmentação (AC, 1min30)

**Mostrar:** tabela de VLANs do README ou `docs/03-plano-de-enderecamento-ip.md`.

- "Segmentamos a rede em **VLANs**: Administrativo/Financeiro (10), Comercial/RH/Recepção (20), TI e servidores (30), câmeras (40), visitantes (50) e VoIP (60). A filial tem 110, 120 e 150."
- "Usamos **um /24 por VLAN**, com o **terceiro octeto igual ao número da VLAN**: VLAN 10 é 192.168.10.0, VLAN 40 é 192.168.40.0. A máscara é 255.255.255.0."
- "O gateway é sempre o **.1**. De .10 a .99 ficam os IPs fixos (servidores, impressoras); de **.100 a .200** é o pool do DHCP."
- "Um /24 tem **254 hosts**. A maior VLAN usa uns 35, então sobra espaço para os 150 dispositivos."
- "A segmentação também é segurança: a rede de **visitantes** só acessa a Internet." (no Packet Tracer: Laptop-Visitante `ping 8.8.8.8` funciona, `ping 192.168.10.100` falha → "é a **ACL** bloqueando")

## Bloco 3 — Os serviços TCP/IP implementados (AJ, 1min30)

**Mostrar:** tabela de serviços no `docs/04-configuracao-dos-servicos-docker.md` e o Packet Tracer.

- "O enunciado pede pelo menos dois serviços; implementamos **quatro**, todos na VLAN 30:"
  - "**DHCP** (192.168.30.10, porta 67/UDP): entrega IP, máscara, gateway e DNS automaticamente."
  - "**DNS** (192.168.30.11, porta 53): traduz `intranet.agrotech.local` para o IP do servidor web e encaminha nomes externos para a Internet."
  - "**Web** (192.168.30.12, porta 80): hospeda a página interna, a intranet."
  - "**FTP** (192.168.30.13, porta 21): transferência de arquivos, como manuais técnicos."
- No Packet Tracer, no **PC-ADM**: `ipconfig` → "recebeu IP de um servidor que está em **outra VLAN**, graças ao **ip helper-address** no roteador". Navegador em `http://intranet.agrotech.local` → "o DNS resolveu e o servidor web respondeu."

## Bloco 4 — O funcionamento da solução utilizando Docker (AC, 2min)

**Mostrar:** terminal + Docker Desktop + navegador.

1. Rodar `powershell -ExecutionPolicy Bypass -File .\docker\scripts\testar-tudo.ps1` e, enquanto roda:
   - "Cada serviço é um **container**: DHCP no .10, DNS no .11, Web no .12 e FTP no .13. Os IPs são os mesmos do plano e do Packet Tracer."
   - "Tudo é definido no **docker-compose.yml**: a rede `agrotech-lan` imita a VLAN 30 e cada serviço tem IP fixo. As configurações ficam em arquivos no GitHub, montados nos containers."
2. Apontar o **Teste 1**: "o cliente começou com o IP que o Docker deu e trocou pelo IP do nosso DHCP. No log aparecem as quatro mensagens: **DISCOVER, OFFER, REQUEST, ACK**."
3. Apontar o **Teste 2**: "o DNS respondeu `intranet` com .12, o `erp` como apelido (CNAME) e encaminhou `google.com` para a Internet."
4. Navegador em `http://localhost:8080`: "e aqui a página interna servida pelo nginx."
5. Resumo: "os quatro testes passaram. Qualquer pessoa reproduz isso com o passo a passo do repositório."

## Bloco 5 — As principais dificuldades e decisões técnicas (AJ, 1min)

- "A maior limitação: no **Docker Desktop do Windows**, os containers ficam numa máquina virtual e o broadcast do DHCP não chega na rede física. Por isso o DHCP é demonstrado **entre containers**. Em produção, o DHCP ficaria no servidor da VLAN 30 atendendo as outras VLANs pelo **relay**, que é o que mostramos no Packet Tracer."
- "Escolhemos o **dnsmasq** por ser leve e fazer DHCP e DNS; usamos dois containers separados para cada serviço ter seu IP."
- "Resolvemos dois problemas práticos: o arquivo de DNS do cliente, que o Docker trava, e a primeira oferta do DHCP que se perdia, resolvida com `dhcp-broadcast`."
- "A **VPN** entre matriz e filial ficou documentada, porque o Packet Tracer não tem pfSense; na simulação usamos rotas estáticas."

**Fechamento (AC, 15 s):** "Está tudo no GitHub com o passo a passo para reproduzir. Obrigada!"

---

## Plano B (se algo falhar na hora)

| Problema | O que fazer |
|---|---|
| Docker não sobe / sem Internet | Mostrar as evidências já gravadas em `evidencias/*.txt` e os prints `docker-*.png` |
| Packet Tracer trava | Mostrar os prints `pt-*.png` em `docs/05-documentacao-e-evidencias.md` |
| Primeiro ping falha no PT | Normal (ARP). Rodar o ping de novo |
| Porta 8080 ocupada | Trocar para `"8081:80"` no `docker-compose.yml` e usar `http://localhost:8081` |

---

## Perguntas prováveis do professor (respostas curtas)

**O que é VLAN?**
Uma rede local virtual: divide um switch físico em várias redes lógicas isoladas. Dispositivos de VLANs diferentes não se comunicam diretamente; precisam passar por um roteador. Isso separa setores, reduz broadcast e aumenta a segurança.

**Por que dividir em sub-redes?**
Cada VLAN precisa de uma rede IP própria para que o roteador saiba para onde encaminhar. Sub-redes menores reduzem o domínio de broadcast e permitem aplicar regras de firewall por setor.

**Por que /24?**
Dá 254 hosts por rede, mais do que suficiente para o crescimento até 150 dispositivos, e é fácil de ler. Faixa privada não falta, então não precisamos economizar com VLSM.

**Como funciona o DHCP? (DORA)**
**D**iscover: o cliente, sem IP, manda broadcast procurando um servidor. **O**ffer: o servidor oferece um IP. **R**equest: o cliente pede formalmente aquele IP. **A**ck: o servidor confirma e entrega a concessão com máscara, gateway, DNS e tempo de lease.

**O que faz o `ip helper-address`?**
Broadcast não atravessa roteador. O helper faz o roteador pegar o DHCPDISCOVER da VLAN e reenviá-lo em unicast para o servidor DHCP (192.168.30.10), informando de qual rede veio (giaddr). Assim um único servidor atende todas as VLANs, inclusive a filial.

**O que o DNS faz?**
Traduz nomes em IPs. `intranet.agrotech.local` vira 192.168.30.12. Nomes de fora (google.com) são encaminhados para 8.8.8.8 e 1.1.1.1. Também temos CNAME (apelido: `erp` → `intranet`) e o reverso (IP → nome).

**O que é trunk?**
Uma porta que transporta várias VLANs no mesmo cabo, marcando cada quadro com o número da VLAN (tag 802.1Q). Usamos trunk entre os switches e entre o switch core e o roteador.

**O que é VLAN nativa?**
A VLAN cujos quadros passam sem tag no trunk. Mudamos para a 99, sem nenhum host, para evitar ataques de VLAN hopping.

**O que é router-on-a-stick?**
Roteamento entre VLANs usando um único cabo trunk até o roteador, que tem uma subinterface para cada VLAN (Gi0/0.10, Gi0/0.20...). Cada subinterface é o gateway daquela VLAN.

**Por que não um switch camada 3?**
Com router-on-a-stick todo tráfego entre setores passa pelo firewall pfSense e pode ser filtrado. Para o tamanho da empresa, 1 Gbps no trunk é suficiente. Switch L3 seria a evolução se o tráfego interno crescer.

**O que é VPN Site-to-Site?**
Um túnel criptografado (IPSec) entre os firewalls da matriz e da filial pela Internet. Para os usuários, parece que as duas unidades estão na mesma rede, mas o tráfego vai cifrado.

**Por que a VPN não está no Packet Tracer?**
O projeto real usa pfSense, que não existe no PT. Simulamos a conectividade com rotas estáticas e mostramos o conceito de túnel com GRE (que encapsula mas não criptografa). A configuração do IPSec no pfSense está documentada no doc 6.

**O que a ACL dos visitantes faz?**
Na entrada da subinterface dos visitantes, permite DHCP e consulta DNS, **bloqueia** todas as redes internas (192.168.0.0/16) e libera o resto, que é a Internet.

**Por que Docker?**
Cada serviço fica isolado em um container leve, com configuração em arquivos versionados no Git. Qualquer pessoa reproduz o ambiente com um comando (`docker compose up`), e um serviço com problema é recriado em segundos.

**Qual a diferença entre imagem e container?**
A imagem é o "molde" (sistema + programa, só leitura). O container é uma instância rodando a partir da imagem.

**O que cada parte do compose faz?**
- `services`: os containers (dhcp, dns, web, ftp, cliente).
- `build` / `image`: de onde vem a imagem (Dockerfile nosso ou imagem oficial do nginx).
- `volumes`: monta os arquivos de configuração do repositório dentro do container.
- `networks` + `ipv4_address`: liga o container na `agrotech-lan` com IP fixo.
- `ports: "8080:80"`: publica a porta 80 do nginx na 8080 do Windows.
- `cap_add: NET_ADMIN`: dá ao DHCP permissão de mexer na rede (responder a cliente sem IP).
- `profiles: ["test"]`: o cliente só sobe quando pedimos.
- `ipam` / `subnet` / `gateway` / `ip_range`: define a sub-rede da VLAN 30 e restringe os IPs automáticos do Docker a .1–.14, para não colidir com o pool do DHCP.

**Por que o DHCP não atende o seu notebook de verdade?**
O Docker Desktop no Windows roda numa VM; a rede dos containers não tem ligação de camada 2 com a rede física, e DHCP depende de broadcast. Por isso a prova é entre containers. Em produção, ficaria num servidor Linux na VLAN 30, com relay.

**Por que o dnsmasq?**
É leve, faz DHCP e DNS, tem configuração curta e logs claros. Usamos dois containers separados (um só DHCP, outro só DNS) para cada serviço ter seu IP e falhar de forma independente.

**O que é PortFast e BPDU Guard?**
PortFast coloca a porta de acesso em encaminhamento imediatamente (sem esperar o Spanning Tree), para o PC conseguir pedir DHCP logo. BPDU Guard desliga a porta se alguém ligar um switch nela, protegendo a topologia.
