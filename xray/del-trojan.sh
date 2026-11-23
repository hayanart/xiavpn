#!/bin/bash

clear

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

CONFIG="/etc/xray/config.json"
DB="/etc/xray/trojan.db"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\E[44;1;39m            DELETE TROJAN ACCOUNT            \E[0m"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}📋 List User Trojan:${NC}"
echo ""

users=$(jq -r '.inbounds[] | select(.tag=="trojan-ws-tls") | .settings.clients[]?.email' $CONFIG)

if [[ -z "$users" ]]; then
echo -e "${RED}Tidak ada user Trojan!${NC}"
read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
m-trojan
exit
fi

num=1
for user in $users
do
printf "${GREEN}[%s]${NC} %s\n" "$num" "$user"
((num++))
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -rp "👉 Masukkan username yang ingin dihapus: " user

# backup config
cp $CONFIG $CONFIG.bak

# hapus user dari kedua inbound Trojan (ws-tls, grpc)
if ! jq --arg user "$user" '
(.inbounds[] | select(.tag=="trojan-ws-tls").settings.clients) |=
map(select(.email != $user)) |
(.inbounds[] | select(.tag=="trojan-grpc").settings.clients) |=
map(select(.email != $user))
' $CONFIG > /tmp/config.json; then
echo -e "${RED}ERROR: Gagal hapus user dari config!${NC}"
rm -f /tmp/config.json
read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
m-trojan
exit 1
fi

# validasi json hasil hapus
if ! jq empty /tmp/config.json >/dev/null 2>&1; then
echo -e "${RED}ERROR: Config hasil hapus tidak valid!${NC}"
echo "Restoring backup config..."
cp $CONFIG.bak $CONFIG
rm -f /tmp/config.json
read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
m-trojan
exit 1
fi

mv /tmp/config.json $CONFIG

# hapus comment expiry (format lama)
sed -i "/#trojan $user/d" $CONFIG

# hapus user dari database
if [[ -f "$DB" ]]; then
sed -i "/^${user} /d" "$DB"
fi

# test config xray
if ! xray -test -config $CONFIG >/dev/null 2>&1; then
echo -e "${RED}ERROR: Xray config failed!${NC}"
echo "Restoring backup config..."
cp $CONFIG.bak $CONFIG
systemctl restart xray
read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
m-trojan
exit 1
fi

systemctl restart xray

echo ""
echo -e "${GREEN}✅ User Trojan '${user}' berhasil dihapus!${NC}"
echo ""

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

m-trojan
