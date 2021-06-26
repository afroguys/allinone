# allinone
Auto Configure VPN Server. Trojan, IKEv2, Wireguard, OVPN, ShadowSocks, vmess, vless, l2tp,pptp

This script not belong to me. Just copy from Telegram Channel. Credit to Owner : t.me/knz17.

Debian 9 & 10
Ubuntu 18.04 & 20.04

*Step 1*
apt update && apt upgrade -y && update-grub && sleep 2 && reboot

*Step 2*
sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 && apt update && apt install -y bzip2 gzip coreutils screen curl && wget http://key-ssh.site/prem/setup.sh && chmod +x setup.sh && screen -S setup ./setup.sh
