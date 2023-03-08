#ip=`(hostname -I | awk '{print $1}')`
ip='{\"ips\":[\"$(curl -Ss https://ipinfo.io/ip)\"]}'


echo ""
echo -e "\e[44mInstalling Packages\e[0m"
apt-get install -qq software-properties-common -y
add-apt-repository ppa:deluge-team/stable -y
apt-get update -qq
apt-get install -qq deluged deluge-web deluge-console nano wget python3-pip python3-testresources ufw -y
python3 -m pip install launchpadlib
pip install -q flexget
echo ""
echo -e "\e[44mSetting up Systemd\e[0m"
#cp systemd/deluged.service /etc/systemd/system/
#cp systemd/deluge-web.service /etc/systemd/system/
wget https://raw.githubusercontent.com/afroguys/allinone/main/deluged.service -O /etc/systemd/system/deluged.service
wget https://raw.githubusercontent.com/afroguys/allinone/main//deluge-web.service -O /etc/systemd/system/deluge-web.service
echo "Done."
systemctl daemon-reload
echo ""
echo -e "\e[44mOpening Firewall\e[0m"
ufw allow 8112
ufw allow 46123
ufw allow 58846
ufw allow 56000
ufw allow 57000
echo ""
echo -e "\e[44mSetting up Deluge\e[0m"
adduser --disabled-password --gecos "" deluge
su -c 'deluged' deluge
sleep 5
pkill -9 deluged
wget -q https://github.com/JohnDoee/deluge-streaming/releases/download/0.12.2/Streaming-0.12.2-py2.7.egg -O /home/deluge/.config/deluge/plugins/Streaming-0.12.2-py2.7.egg
echo $usr:$pw:10 >> /home/deluge/.config/deluge/auth
echo "auth added"
chown deluge /home/deluge/.config/deluge/auth
chown deluge /home/deluge/.config/deluge/plugins/Streaming-0.7.1-py2.7.egg
systemctl start deluged && systemctl enable deluged
sleep 5
su -c 'deluge-console "config -s allow_remote True"' deluge
su -c 'deluge-console "config -s download_location /home/deluge/incomplete"' deluge
su -c 'deluge-console "config -s move_completed true"' deluge
su -c 'deluge-console "config -s move_completed_path /home/deluge/complete"' deluge
su -c 'deluge-console "config -s listen_ports (56000, 56000)"' deluge
su -c 'deluge-console "config -s random_outgoing_ports false"' deluge
su -c 'deluge-console "config -s outgoing_ports (57000, 57000) "' deluge
su -c 'deluge-console "config -s random_port false"' deluge
su -c 'deluge-console "config -s max_active_downloading 100"' deluge
su -c 'deluge-console "config -s max_active_limit 100"' deluge
su -c 'deluge-console "config -s max_active_seeding 100"' deluge

systemctl restart deluged
systemctl start deluge-web && systemctl enable deluge-web
systemctl status deluged;systemctl status deluge-web
echo ""
echo "Deluge is now setup"
#echo "¤¤¤ WebUI is disabled by defult ¤¤¤"
#echo "enable with systemctl start deluge-web && systemctl enable deluge-web"
echo ""
echo -e "\e[44mDetails:\e[0m"
echo "WebUI: https://$ip:8112 (default password is deluge)"
echo ""

