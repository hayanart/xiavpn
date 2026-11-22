#!/bin/bash
# ==========================================
# Setup Script xiavpn
# XRAY + WireGuard + UDP ZIVPN
# ==========================================

echo "" > /root/log-install.txt

cd "$(dirname "$0")"

# Installer harus non-interaktif (sekali-klik): jangan sampai apt/dpkg
# berhenti nanya (mis. conffile) dan nungguin jawaban.
# (Tes 2026-11-23: apt-get upgrade sempat macet ±10 mnt di prompt
# conffile /etc/default/dropbear.)
export DEBIAN_FRONTEND=noninteractive

clear

# ==========================================
# COLOR
# ==========================================

red='\e[1;31m'
green='\e[0;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
cyan='\e[1;36m'
NC='\e[0m'

# ==========================================
# FUNCTION
# ==========================================

function info() {
    echo -e "${green}[INFO]${NC} $1"
}

function warn() {
    echo -e "${yellow}[WARNING]${NC} $1"
}

function error() {
    echo -e "${red}[ERROR]${NC} $1"
}

# ==========================================
# TIMER
# ==========================================

start_time=$(date +%s)

# ==========================================
# CHECK ROOT
# ==========================================

if [ "${EUID}" -ne 0 ]; then
    error "Script harus dijalankan sebagai root."
    exit 1
fi

# ==========================================
# CHECK VIRTUALIZATION
# ==========================================

if [ "$(systemd-detect-virt)" == "openvz" ]; then
    error "OpenVZ tidak didukung. Gunakan KVM/VMWare."
    exit 1
fi

# ==========================================
# FIX /etc/hosts
# ==========================================

localip=$(hostname -I | awk '{print $1}')
hostname=$(hostname)

domainline=$(grep -w "$hostname" /etc/hosts | awk '{print $2}')

if [[ "$hostname" != "$domainline" ]]; then
    echo "$localip $hostname" >> /etc/hosts
fi

# ==========================================
# CREATE REQUIRED FOLDER
# ==========================================

mkdir -p /etc/xray
mkdir -p /etc/v2ray
mkdir -p /var/lib

for file in domain scdomain; do
    touch /etc/xray/$file
    touch /etc/v2ray/$file
    touch /root/$file
done

touch /var/lib/ipvps.conf

# ==========================================
# SET TIMEZONE
# ==========================================

ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# ==========================================
# UPDATE & INSTALL PACKAGE
# ==========================================

info "Installing dependencies..."

apt update -y

apt install -y \
curl \
wget \
git \
screen \
unzip \
bzip2 \
gzip \
coreutils \
python3 \
python3-pip \
iptables \
iptables-persistent \
netfilter-persistent \
vnstat \
openssl \
ufw

# Pastikan tool penting beneran kepasang. apt install di atas sempat
# gagal diam-diam untuk vnstat (output dibuang ke /dev/null), jadi
# cek ulang dan pasang yang masih hilang.
for _tool in vnstat curl wget git; do
    if ! command -v "$_tool" >/dev/null 2>&1; then
        info "Memasang ulang $_tool yang belum kepasang..."
        apt install -y "$_tool"
    fi
done
unset _tool

# ==========================================
# INSTALL LINUX HEADER
# ==========================================

kernelver=$(uname -r)
headerpkg="linux-headers-$kernelver"

if ! dpkg -s $headerpkg >/dev/null 2>&1; then
    info "Installing $headerpkg..."
    apt install -y $headerpkg
fi

# ==========================================
# DOMAIN SETUP
# ==========================================

clear

echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${cyan}         DOMAIN SETUP${NC}"
echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Domain bisa dikirim lewat env DOMAIN (dipakai installer sekali-klik),
# kalau kosong tetap ditanya secara interaktif.
domain="${DOMAIN:-}"
if [[ -z "$domain" ]]; then
    read -rp "Masukkan domain kamu : " domain
fi

if [[ -z "$domain" ]]; then
    error "Domain tidak boleh kosong!"
    exit 1
fi

echo "$domain" > /root/domain

for dfile in domain scdomain; do
    echo "$domain" > /etc/xray/$dfile
    echo "$domain" > /etc/v2ray/$dfile
    echo "$domain" > /root/$dfile
done

echo "IP=$domain" > /var/lib/ipvps.conf

echo ""
info "Domain berhasil diset: $domain"

sleep 2

# ==========================================
# RUN INSTALLER
# ==========================================

info "Installing NGINX Reverse Proxy..."
bash install/nginx.sh

info "Installing XRAY Core..."
bash install/xray.sh

info "Installing SSH Websocket..."
bash install/ssh.sh

info "Installing WireGuard..."
bash install/wg.sh

info "Installing UDP ZIVPN..."
bash install/zivpn.sh

# ==========================================
# COPY MENU COMMAND
# ==========================================

info "Menyalin command menu..."

cp -f ssh/m-ssh /usr/bin/

cp -f xray/m-vmess /usr/bin/
cp -f xray/m-vless /usr/bin/
cp -f xray/m-trojan /usr/bin/
cp -f xray/m-ssws /usr/bin/

cp -f wg/m-wg /usr/bin/

cp -f udp/m-zivpn /usr/bin/

cp -f slowdns/m-slowdns /usr/bin/

cp -f tools/tools-menu /usr/bin/

cp -f tools/backup.sh /usr/bin/
cp -f tools/speedtest.sh /usr/bin/
cp -f tools/domain.sh /usr/bin/
cp -f tools/running.sh /usr/bin/

cp -f menu.sh /usr/bin/menu

# ==========================================
# SET PERMISSION
# ==========================================

chmod +x /usr/bin/menu

chmod +x /usr/bin/m-ssh
chmod +x /usr/bin/m-vmess
chmod +x /usr/bin/m-vless
chmod +x /usr/bin/m-trojan
chmod +x /usr/bin/m-ssws
chmod +x /usr/bin/m-wg
chmod +x /usr/bin/m-zivpn
chmod +x /usr/bin/m-slowdns

chmod +x /usr/bin/tools-menu
chmod +x /usr/bin/backup.sh
chmod +x /usr/bin/speedtest.sh
chmod +x /usr/bin/domain.sh
chmod +x /usr/bin/running.sh

chmod +x ssh/*.sh
chmod +x xray/*.sh
chmod +x wg/*.sh
chmod +x udp/*.sh
chmod +x tools/*.sh
chmod +x slowdns/*.sh

# ==========================================
# COPY RUNTIME SCRIPT
# ==========================================

info "Menyalin semua submenu ke /etc/xiavpn/..."

mkdir -p /etc/xiavpn/{ssh,xray,wg,udp,tools,slowdns}

cp -r ssh/* /etc/xiavpn/ssh/
cp -r xray/* /etc/xiavpn/xray/
cp -r wg/* /etc/xiavpn/wg/
cp -r udp/* /etc/xiavpn/udp/
cp -r tools/* /etc/xiavpn/tools/
cp -r slowdns/* /etc/xiavpn/slowdns/

chmod +x /etc/xiavpn/*/*.sh

# ==========================================
# AUTO MENU LOGIN
# ==========================================

cat > /root/.profile <<-EOF
if [ "\$BASH" ]; then
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi

clear
menu
EOF

chmod 644 /root/.profile

# ==========================================
# CLEAN FILE
# ==========================================

rm -f cf
rm -f ins-xray.sh

# ==========================================
# FINISH
# ==========================================

end_time=$(date +%s)

elapsed=$((end_time - start_time))

clear

echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${green}      INSTALLATION DONE${NC}"
echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e " SSH         : INSTALLED"
echo -e " XRAY        : INSTALLED"
echo -e " WireGuard   : INSTALLED"
echo -e " UDP ZIVPN   : INSTALLED"

echo ""
echo -e " Installation Time : $((elapsed / 60)) menit $((elapsed % 60)) detik"

echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${green}♻️ VPS akan reboot dalam 10 detik...${NC}"

sleep 10

reboot
