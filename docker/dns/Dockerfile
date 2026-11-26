# Imagem do servidor DNS da AgroTech (dnsmasq em modo somente-DNS)
FROM alpine:3.20

# bind-tools traz o "dig", útil para diagnóstico dentro do próprio container.
RUN apk add --no-cache dnsmasq bind-tools

# DNS usa a porta 53 (UDP para consultas comuns, TCP para respostas grandes)
EXPOSE 53/udp 53/tcp

ENTRYPOINT ["dnsmasq", "--keep-in-foreground", "--conf-file=/etc/dnsmasq.conf"]
