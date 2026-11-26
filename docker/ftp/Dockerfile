# Imagem do servidor FTP da AgroTech (vsftpd)
FROM alpine:3.20

RUN apk add --no-cache vsftpd

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 21 = canal de controle; 21100-21110 = faixa de portas do modo passivo
EXPOSE 21/tcp 21100-21110/tcp

ENTRYPOINT ["/entrypoint.sh"]
