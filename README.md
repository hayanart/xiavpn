# xiavpn

## Features

| Category    | Features                                                                          |
| ----------- | --------------------------------------------------------------------------------- |
| SSH WS      | OpenSSH, Dropbear, SSH WS, SSH SSL WS, Enhanced Payload, UDP Custom, BadVPN UDPGW |
| XRAY Core   | VMess, VLESS, Trojan, Shadowsocks, gRPC, NGINX Reverse Proxy, Auto SSL            |
| WireGuard   | WireGuard VPN, Client Generator, QR Code                                          |
| UDP Tunnel  | UDP Custom, ZIVPN UDP, BadVPN UDPGW                                               |
| Management  | Backup, Domain Manager, Speedtest, Service Checker, Traffic Monitor               |
| Dashboard   | Interactive Panel, Service Status, User Statistics, Traffic Statistics            |
| Go Services | Native Dropbear WS, Native Stunnel WS, Multi-Connection Support                   |

---

## Screenshot

![dashboard1](./img/menu.gif)

Open menu:

```bash
menu
```

---

## Quick Install

> Note: This script must be run as root!

Satu perintah (sekali klik install):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/hayanart/xiavpn/main/install.sh)"
```

Langsung dengan domain (tanpa ditanya lagi):

```bash
DOMAIN=contoh.com bash -c "$(curl -fsSL https://raw.githubusercontent.com/hayanart/xiavpn/main/install.sh)"
```

Installer akan memasang git/curl/screen, mematikan IPv6, mengunduh repo xiavpn, lalu menjalankan `setup.sh` di dalam screen (`xiavpn-setup`) — kalau SSH putus, balik dengan `screen -r xiavpn-setup`. Di akhir install, VPS akan reboot otomatis.

Butuh curl dulu. Kalau belum ada: `apt install -y curl`
---

## Default Ports

| Service        | Port    |
| -------------- | ------- |
| OpenSSH        | 22      |
| Dropbear       | 109,143 |
| SSH WS         | 2082    |
| SSH SSL WS     | 2096    |
| BadVPN UDPGW   | 7300    |
| UDP Custom     | 1-65535 |
| VMess TLS      | 443     |
| VMess None TLS | 80      |
| VLESS TLS      | 443     |
| Trojan TLS     | 443     |
| Shadowsocks WS | 443     |

---

## Debugging

Check listening ports:

```bash
ss -tulpn
```

Check NGINX:

```bash
nginx -t
systemctl status nginx
```

Check XRAY:

```bash
xray -test -config /etc/xray/config.json
systemctl status xray
```

Check SSH WS:

```bash
systemctl status ws-dropbear
systemctl status ws-stunnel
```

Check UDP Tunnel:

```bash
systemctl status udp-custom
systemctl status udpgw
```

---

## Compatibility

| OS           | Status        |
| ------------ | ------------- |
| Debian 12    | ⭐ Recommended |
| Debian 11    | ✅ Supported   |
| Ubuntu 22.04 | ✅ Supported   |
| Ubuntu 20.04 | ⚠ Limited     |
| Debian 10    | ❌ Deprecated  |
| OpenVZ       | ❌ Unsupported |
| KVM          | ✅ Recommended |
| VMware       | ✅ Recommended |

---

## ⚠ Notes

* Recommended fresh VPS installation
* Recommended minimum RAM 1GB
* Domain required for XRAY TLS
* Cloudflare supported
* Enhanced payload supported

---

## ❤️ Credits

* XTLS / Xray-core
* BadVPN
* WireGuard
* acme.sh
* NGINX
