# Servidores de infraestrutura (VLAN 30) — valores para o Packet Tracer

No Packet Tracer, cada serviço fica em um **Server-PT** próprio, com o mesmo IP do container correspondente no Docker. Assim o plano de endereçamento é idêntico nos dois ambientes:

| Server-PT | IP | Serviço ligado | Equivale ao container |
|---|---|---|---|
| SRV-DHCP | 192.168.30.10 | DHCP | `agrotech-dhcp` |
| SRV-DNS | 192.168.30.11 | DNS | `agrotech-dns` |
| SRV-WEB | 192.168.30.12 | HTTP | `agrotech-web` |
| SRV-FTP | 192.168.30.13 | FTP | `agrotech-ftp` |

> Por que 4 servidores e não 1? Os pools DHCP entregam o DNS **192.168.30.11** e o DNS aponta `intranet` para **.12** e `ftp` para **.13**. Com um único servidor em .10, esses endereços não existiriam e o navegador não abriria a intranet.

---

## 1. Configuração IP de cada servidor (todos iguais, só muda o IP)

Clique no servidor → aba **Desktop** → **IP Configuration** → marque **Static**:

| Campo | SRV-DHCP | SRV-DNS | SRV-WEB | SRV-FTP |
|---|---|---|---|---|
| IPv4 Address | 192.168.30.10 | 192.168.30.11 | 192.168.30.12 | 192.168.30.13 |
| Subnet Mask | 255.255.255.0 | 255.255.255.0 | 255.255.255.0 | 255.255.255.0 |
| Default Gateway | 192.168.30.1 | 192.168.30.1 | 192.168.30.1 | 192.168.30.1 |
| DNS Server | 192.168.30.11 | 192.168.30.11 | 192.168.30.11 | 192.168.30.11 |

O **Default Gateway** é obrigatório no SRV-DHCP: sem ele, o servidor não consegue responder aos pedidos que chegam de outras VLANs e da filial pelo `ip helper-address`.

**Desligue os serviços que não forem daquele servidor.** O Server-PT vem com HTTP, HTTPS, DNS e outros ligados por padrão. Em cada servidor, vá em **Services** e deixe **On** somente o serviço dele (no SRV-WEB, deixe HTTP On e pode desligar HTTPS).

---

## 2. SRV-DHCP (192.168.30.10) — aba Services → DHCP

1. Marque **Service: On**.
2. O pool **serverPool** já existe e não pode ser apagado: edite-o para a VLAN 30 (primeira linha da tabela), clique em **Save**.
3. Para cada outra linha: preencha os campos, clique em **Add**.

| Pool Name | Default Gateway | DNS Server | Start IP Address | Subnet Mask | Maximum Number of Users |
|---|---|---|---|---|---|
| serverPool (VLAN 30) | 192.168.30.1 | 192.168.30.11 | 192.168.30.100 | 255.255.255.0 | 101 |
| VLAN10-ADM | 192.168.10.1 | 192.168.30.11 | 192.168.10.100 | 255.255.255.0 | 101 |
| VLAN20-COM | 192.168.20.1 | 192.168.30.11 | 192.168.20.100 | 255.255.255.0 | 101 |
| VLAN40-CAM | 192.168.40.1 | 192.168.30.11 | 192.168.40.100 | 255.255.255.0 | 101 |
| VLAN50-VISIT | 192.168.50.1 | 192.168.30.11 | 192.168.50.100 | 255.255.255.0 | 101 |
| VLAN60-VOIP | 192.168.60.1 | 192.168.30.11 | 192.168.60.100 | 255.255.255.0 | 101 |
| VLAN110-FIL-ADM | 192.168.110.1 | 192.168.30.11 | 192.168.110.100 | 255.255.255.0 | 101 |
| VLAN120-FIL-OFI | 192.168.120.1 | 192.168.30.11 | 192.168.120.100 | 255.255.255.0 | 101 |
| VLAN150-FIL-VIS | 192.168.150.1 | 192.168.30.11 | 192.168.150.100 | 255.255.255.0 | 101 |

Deixe **TFTP Server** e **WLC Address** como 0.0.0.0. *Maximum Number of Users* = 101 faz o pool ir de .100 até .200, igual ao Docker.

Como o servidor escolhe o pool: o roteador, ao repassar o pedido com `ip helper-address`, coloca no pacote o IP da subinterface de origem (campo *giaddr*, por exemplo 192.168.10.1). O servidor usa o pool cuja rede contém esse endereço.

---

## 3. SRV-DNS (192.168.30.11) — aba Services → DNS

1. Marque **DNS Service: On**.
2. Para cada linha: preencha **Name**, escolha o **Type**, preencha **Address** e clique em **Add**.

| Name | Type | Address / Host Name |
|---|---|---|
| fw.agrotech.local | A Record | 192.168.30.1 |
| dhcp.agrotech.local | A Record | 192.168.30.10 |
| dns.agrotech.local | A Record | 192.168.30.11 |
| intranet.agrotech.local | A Record | 192.168.30.12 |
| ftp.agrotech.local | A Record | 192.168.30.13 |
| erp.agrotech.local | CNAME | intranet.agrotech.local |

---

## 4. SRV-WEB (192.168.30.12) — aba Services → HTTP

1. **HTTP: On** (HTTPS pode ficar Off).
2. Na lista de arquivos, clique em **index.html** → **(edit)**.
3. Apague o conteúdo e cole:

```html
<html>
<head><title>Intranet AgroTech</title></head>
<body bgcolor="#faf7f2">
<h1><font color="#2e7d32">AgroTech</font> - Intranet</h1>
<p>AgroTech Solucoes Agricolas Ltda. - Matriz Goiania / Filial Anapolis</p>
<hr>
<h3>Servicos da VLAN 30</h3>
<p>DHCP: 192.168.30.10 | DNS: 192.168.30.11 | Web: 192.168.30.12 | FTP: 192.168.30.13</p>
<p>Pagina servida pelo SRV-WEB (Packet Tracer).</p>
</body>
</html>
```

4. Clique em **Save** e confirme **Yes**.

O Packet Tracer tem um navegador simplificado: ele não aplica CSS moderno. Por isso esta página é mais simples que a do Docker (`docker/web/html/index.html`).

---

## 5. SRV-FTP (192.168.30.13) — aba Services → FTP

1. **Service: On**.
2. Em **User Setup**: Username `agrotech`, Password `agrotech123`, marque **Write, Read, Delete, Rename, List** e clique em **Add**.
3. (Opcional) Remova o usuário padrão `cisco` selecionando-o e clicando em **Remove**.

Teste num PC (Desktop → Command Prompt):

```
C:\> ftp 192.168.30.13
Username: agrotech
Password: agrotech123
ftp> dir
ftp> quit
```
