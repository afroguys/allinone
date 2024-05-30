#!/bin/bash

# Function to check if the user is root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

# Function to check OS version and add the apt repository
check_os() {
    if [ -f /etc/debian_version ]; then
        OS="Debian"
        apt update && apt upgrade -y
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        if [ "$DISTRIB_ID" == "Ubuntu" ]; then
            OS="Ubuntu"
            apt update && apt upgrade -y
        fi
    else
        echo "Unsupported OS"
        exit 1
    fi
}

# Function to install Deluge
install_deluge() {
    apt install -y software-properties-common
    add-apt-repository ppa:deluge-team/stable
    apt update
    apt install -y deluged deluge-web deluge-console
    useradd --no-create-home --shell /usr/sbin/nologin deluge
    mkdir -p /var/lib/deluge
    chown deluge:deluge /var/lib/deluge
    cat <<EOF > /etc/systemd/system/deluged.service
[Unit]
Description=Deluge Bittorrent Client Daemon
After=network-online.target

[Service]
Type=simple
User=deluge
Group=deluge
UMask=002
ExecStart=/usr/bin/deluged -d -l /var/log/deluged.log -L info
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    cat <<EOF > /etc/systemd/system/deluge-web.service
[Unit]
Description=Deluge Bittorrent Client Web Interface
After=network-online.target

[Service]
Type=simple
User=deluge
Group=deluge
UMask=002
ExecStart=/usr/bin/deluge-web -l /var/log/deluge-web.log -L info
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable deluged
    systemctl enable deluge-web
    systemctl start deluged
    systemctl start deluge-web
    echo "Deluge installation and configuration completed."
}

# Function to install Rclone
install_rclone() {
    curl https://rclone.org/install.sh | bash
    echo "Rclone installation completed."
}

# Function to install Plex Media Server
install_plex() {
    curl https://downloads.plex.tv/plex-keys/PlexSign.key | apt-key add -
    echo "deb https://downloads.plex.tv/repo/deb public main" | tee /etc/apt/sources.list.d/plexmediaserver.list
    apt update
    apt install -y plexmediaserver
    systemctl enable plexmediaserver
    systemctl start plexmediaserver
    echo "Plex Media Server installation completed."
}

# Main menu
main_menu() {
    echo "Choose an option to install:"
    echo "1. Install Deluge"
    echo "2. Install Rclone"
    echo "3. Install Plex Media Server"
    echo "4. Exit"
    read -p "Enter your choice [1-4]: " choice

    case $choice in
        1)
            install_deluge
            ;;
        2)
            install_rclone
            ;;
        3)
            install_plex
            ;;
        4)
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            main_menu
            ;;
    esac
}

# Script execution starts here
check_root
check_os
main_menu
