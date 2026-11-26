# Cliente de teste: simula um computador de um funcionário ligado à rede.
FROM alpine:3.20

# bind-tools  -> nslookup e dig (testes de DNS)
# curl        -> requisições HTTP e FTP (testes de Web e FTP)
# busybox-extras -> telnet e outras ferramentas de rede
# udhcpc (cliente DHCP) e iproute2 já vêm no BusyBox/Alpine; iproute2 deixa o "ip" completo
RUN apk add --no-cache bind-tools curl busybox-extras iproute2

# Script que aplica IP, gateway e DNS recebidos do DHCP (substitui o padrão do udhcpc).
COPY udhcpc.script /usr/share/udhcpc/default.script
RUN chmod +x /usr/share/udhcpc/default.script

# Mantém o container ligado para recebermos comandos via "docker compose exec".
CMD ["sleep", "infinity"]
