# Allinone

Auto Configure VPN Server. Trojan, IKEv2, Wireguard, OVPN, ShadowSocks, vmess, vless, l2tp,pptp

This script not belong to me. Just copy from Telegram Channel. Credit to Owner [Knz17](https://t.me/knz17)

**Debian 9 & 10** , 
**Ubuntu 18.04 & 20.04**

**Step 1**
> apt update && apt upgrade -y && update-grub && sleep 2 && reboot

**Step 2**
> sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 && apt update && apt install -y bzip2 gzip coreutils screen curl && https://github.com/afroguys/allinone/raw/main/setup.sh && chmod +x setup.sh && screen -S setup ./setup.sh

This script will doing all the installtion.


![photo_2021-06-26_18-36-44](https://user-images.githubusercontent.com/36734490/123510380-ade3b600-d6ad-11eb-8a0a-461d7618a130.jpg)
![photo_2021-06-26_18-37-00](https://user-images.githubusercontent.com/36734490/123510383-b0461000-d6ad-11eb-8b9d-13a9ca58c8b6.jpg)



