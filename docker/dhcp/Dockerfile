# Imagem do servidor DHCP da AgroTech (dnsmasq em modo somente-DHCP)
FROM alpine:3.20

# dnsmasq: servidor leve de DHCP/DNS. /var/lib/misc guarda o arquivo de leases.
RUN apk add --no-cache dnsmasq \
 && mkdir -p /var/lib/misc

# DHCP usa UDP 67 (servidor) e 68 (cliente)
EXPOSE 67/udp

# -k (--keep-in-foreground): mantém o processo em primeiro plano, como o Docker exige.
# A configuração vem do arquivo montado como volume pelo docker-compose.yml.
ENTRYPOINT ["dnsmasq", "--keep-in-foreground", "--conf-file=/etc/dnsmasq.conf"]
