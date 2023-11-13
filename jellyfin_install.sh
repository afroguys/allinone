#!/bin/bash
# Get the Tailscale IP address
#tailscale_ip=$(tailscale status | grep "IP: " | awk '{print $2}')
ip=$(curl -Ss https://ipinfo.io/ip)

#set up jellyfin

#remove old jellyfin files if existant
sudo rm /etc/apt/sources.list.d/jellyfin.list

#add jellyfin repositories
curl https://repo.jellyfin.org/install-debuntu.sh | sudo bash
wget -O- https://repo.jellyfin.org/install-debuntu.sh | sudo bash

#install dependencies
sudo apt install curl gnupg

#enable the universe repository
sudo add-apt-repository universe

#Download the GPG signing key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg

#Add a repository configuration at /etc/apt/sources.list.d/jellyfin.sources
cat <<EOF | sudo tee /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release )
Suites: $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release )
Components: main
Architectures: $( dpkg --print-architecture )
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF

#update
sudo apt update

#install jellyfin
sudo apt install jellyfin

#start jellyfin
sudo systemctl start jellyfin

#enable jellyfin
sudo systemctl enable jellyfin

#allow jellyfin port
#sudo ufw allow (port)

#check status of jellyfin
sudo systemctl status jellyfin


echo ""Jellyfin is up and running please visit $ip:8096 to continue the setup process"
" > "$file_path"
sudo cat $file_path
