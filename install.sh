#!/bin/bash
# xiavpn — installer sekali klik (one-click install)
#
# Cara pakai (satu perintah, sebagai root):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/hayanart/xiavpn/main/install.sh)"
#
# Dengan domain langsung (tanpa ditanya lagi):
#   DOMAIN=contoh.com bash -c "$(curl -fsSL https://raw.githubusercontent.com/hayanart/xiavpn/main/install.sh)"
#
# Yang dilakukan script ini:
#   1. cek root + tolak OpenVZ
#   2. pasang git, curl, screen
#   3. matikan IPv6
#   4. clone repo xiavpn ke /root/xiavpn (atau pakai folder repo kalau
#      sudah dijalankan dari dalam repo)
#   5. jalankan setup.sh di dalam screen "xiavpn-setup" — kalau SSH
#      putus, balik dengan: screen -r xiavpn-setup
#
# Butuh curl dulu. Kalau belum ada: apt install -y curl

set -e

# Installer harus non-interaktif (sekali-klik): jangan sampai apt/dpkg
# berhenti nanya (mis. conffile) dan nungguin jawaban.
export DEBIAN_FRONTEND=noninteractive

REPO_URL="https://github.com/hayanart/xiavpn.git"
REPO_DIR="/root/xiavpn"
SCREEN_NAME="xiavpn-setup"

# Domain boleh dikirim lewat argumen pertama atau env DOMAIN.
if [ -n "$1" ]; then
    DOMAIN="$1"
fi
export DOMAIN

# ---------- cek root ----------
if [ "${EUID}" -ne 0 ]; then
    echo "ERROR: jalankan sebagai root." >&2
    exit 1
fi

# ---------- tolak OpenVZ ----------
if [ "$(systemd-detect-virt 2>/dev/null)" = "openvz" ]; then
    echo "ERROR: OpenVZ tidak didukung. Gunakan KVM/VMWare." >&2
    exit 1
fi

# ---------- dependensi dasar ----------
echo "[xiavpn] memasang git, curl, screen..."
apt update -y
apt install -y git curl screen sudo

# ---------- matikan IPv6 ----------
sysctl -w net.ipv6.conf.all.disable_ipv6=1 || true
sysctl -w net.ipv6.conf.default.disable_ipv6=1 || true

# ---------- ambil repo ----------
if [ -f "./setup.sh" ] && [ -d "./install" ]; then
    REPO_DIR="$(pwd)"
    echo "[xiavpn] memakai repo lokal: $REPO_DIR"
else
    echo "[xiavpn] mengunduh repo xiavpn..."
    rm -rf "$REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

chmod +x setup.sh uninstall.sh

# ---------- jalankan setup.sh ----------
echo "[xiavpn] memulai setup.sh..."
echo "[xiavpn] kalau SSH putus, balik dengan: screen -r $SCREEN_NAME"
if [ -n "${DOMAIN:-}" ]; then
    echo "[xiavpn] domain: $DOMAIN"
fi

if command -v screen >/dev/null 2>&1; then
    exec screen -S "$SCREEN_NAME" ./setup.sh
else
    ./setup.sh
fi
