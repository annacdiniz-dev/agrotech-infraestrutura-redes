#!/bin/sh
# Cria o usuário de FTP (dados vindos das variáveis de ambiente do compose)
# e inicia o vsftpd em primeiro plano.
set -e

FTP_USER="${FTP_USER:-agrotech}"
FTP_PASS="${FTP_PASS:-agrotech123}"

if ! id "$FTP_USER" >/dev/null 2>&1; then
    adduser -D -h "/home/$FTP_USER" "$FTP_USER"
fi
echo "$FTP_USER:$FTP_PASS" | chpasswd

# Pasta de trabalho com um arquivo de boas-vindas
mkdir -p "/home/$FTP_USER/arquivos"
cat > "/home/$FTP_USER/arquivos/LEIA-ME.txt" <<EOF
Servidor FTP da AgroTech (ftp.agrotech.local - 192.168.30.13)
Pasta para manuais tecnicos, catalogos de pecas e laudos da oficina.
EOF
chown -R "$FTP_USER:$FTP_USER" "/home/$FTP_USER"

echo "vsftpd iniciado - usuario: $FTP_USER"
exec vsftpd /etc/vsftpd/vsftpd.conf
