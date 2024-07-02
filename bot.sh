#!/bin/bash

# === Configuration Variables ===
TELEGRAM_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
PLEX_TOKEN="YOUR_PLEX_TOKEN"
PLEX_URL="http://localhost:32400"
QB_USERNAME="admin"
QB_PASSWORD="adminadmin"  # It's recommended to change this after setup
DOWNLOAD_PATH="/home/$USER/Downloads"
CATEGORIES_PATH="/home/$USER/Categories"
PLEX_CATEGORIES=("movies" "tv_shows")
SERVER_DOMAIN="your_server_domain_or_ngrok_url"

# === Update and Install Necessary Software ===
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip curl jq

# Install qBittorrent-nox (Ensure the source is reliable)
sudo apt install -y qbittorrent-nox

# === Create qBittorrent-nox Service File ===
cat <<EOL | sudo tee /etc/systemd/system/qbittorrent-nox.service
[Unit]
Description=qBittorrent Command Line Client
Documentation=man:qbittorrent-nox(1) https://github.com/qbittorrent/qBittorrent
After=network.target

[Service]
ExecStart=/usr/bin/qbittorrent-nox --webui-port=8080
Restart=on-failure
User=$USER
Group=$USER
UMask=002

[Install]
WantedBy=multi-user.target
EOL

# === Reload systemd daemon to recognize the new service ===
sudo systemctl daemon-reload

# === Enable the qBittorrent-nox service to start on boot ===
sudo systemctl enable qbittorrent-nox

# === Start the qBittorrent-nox service immediately ===
sudo systemctl start qbittorrent-nox

# === Install Python Libraries ===
pip3 install python-telegram-bot qbittorrent-api requests

# === Configure qBittorrent ===
echo "Starting qBittorrent..."
sudo pkill qbittorrent-nox
qbittorrent-nox --webui-port=8080 & sleep 10

echo "Configuring qBittorrent..."
# Perform login and capture cookies
login_response=$(curl -s --cookie-jar /tmp/qbittorrent-cookie.txt -X POST "http://localhost:8080/api/v2/auth/login" -d "username=admin&password=adminadmin")

if [[ $login_response == *"Ok"* ]]; then
    echo "Login successful."
else
    echo "Login failed. Check Web UI access and credentials."
    exit 1
fi

# Set preferences including username and password
preferences_json=$(cat <<EOF
{
    "save_path": "$DOWNLOAD_PATH",
    "web_ui_username": "$QB_USERNAME",
    "web_ui_password": "$(echo -n "$QB_PASSWORD" | md5sum | awk '{print $1}')"
}
EOF
)

echo "Sending preferences JSON: $preferences_json"

preferences_response=$(curl -s --cookie /tmp/qbittorrent-cookie.txt -X POST "http://localhost:8080/api/v2/app/setPreferences" -d "$preferences_json")

echo "Preferences response: $preferences_response"

if [[ $preferences_response == *"Ok"* ]]; then
    echo "Preferences set successfully."
else
    echo "Failed to set preferences. Response: $preferences_response"
    exit 1
fi

# Restart qBittorrent with new settings
pkill qbittorrent-nox
qbittorrent-nox --webui-port=8080 &

# === Create Necessary Directories ===
mkdir -p $DOWNLOAD_PATH
for category in "${PLEX_CATEGORIES[@]}"; do
    mkdir -p "${CATEGORIES_PATH}/${category}"
done

# === Generate Configuration File ===
cat <<EOL > /home/$USER/config.sh
#!/bin/bash

# Configuration variables
TELEGRAM_TOKEN="$TELEGRAM_TOKEN"
PLEX_TOKEN="$PLEX_TOKEN"
PLEX_URL="$PLEX_URL"
QB_USERNAME="$QB_USERNAME"
QB_PASSWORD="$QB_PASSWORD"
DOWNLOAD_PATH="$DOWNLOAD_PATH"
CATEGORIES_PATH="$CATEGORIES_PATH"
PLEX_CATEGORIES=(${PLEX_CATEGORIES[@]})
SERVER_DOMAIN="$SERVER_DOMAIN"
EOL

# === Generate qBittorrent Client Script ===
cat <<EOL > /home/$USER/qbit_client.sh
#!/bin/bash

source /home/$USER/config.sh

# Function to add a torrent
add_torrent() {
    local magnet_link=\$1
    local category=\$2

    echo "Logging into qBittorrent..."
    curl -s --cookie-jar /tmp/qbittorrent-cookie.txt -X POST "http://localhost:8080/api/v2/auth/login" -d "username=\$QB_USERNAME&password=\$QB_PASSWORD"

    echo "Adding torrent..."
    torrent_response=\$(curl -s --cookie /tmp/qbittorrent-cookie.txt -X POST "http://localhost:8080/api/v2/torrents/add" -F "urls=\$magnet_link" -F "savepath=\$DOWNLOAD_PATH" -F "category=\$category")
    torrent_id=\$(echo "\$torrent_response" | jq -r '.[0].hash')

    if [ -z "\$torrent_id" ]; then
        echo "Failed to add torrent. Response: \$torrent_response"
        return 1
    fi

    echo "Selecting movie files only..."
    files_response=\$(curl -s --cookie /tmp/qbittorrent-cookie.txt -X GET "http://localhost:8080/api/v2/torrents/files?hash=\$torrent_id")
    file_ids=\$(echo "\$files_response" | jq -r '.[] | select(.name | endswith(".mp4") or endswith(".mkv") or endswith(".avi")) | .id')
    for file_id in \$file_ids; do
        curl -s --cookie /tmp/qbittorrent-cookie.txt -X POST "http://localhost:8080/api/v2/torrents/filePrio" -d "hash=\$torrent_id&priority=1&id=\$file_id"
    done

    echo "\$torrent_id"
}

# Function to move torrent files to category
move_to_category() {
    local torrent_id=\$1
    local category=\$2

    echo "Moving files to category..."
    files_response=\$(curl -s --cookie /tmp/qbittorrent-cookie.txt -X GET "http://localhost:8080/api/v2/torrents/files?hash=\$torrent_id")
    file_path=\$(echo "\$files_response" | jq -r '.[0].name')

    if [ -z "\$file_path" ]; then
        echo "Failed to get file path. Response: \$files_response"
        return 1
    fi

    mv "\$DOWNLOAD_PATH/\$file_path" "\${CATEGORIES_PATH}/\$category/"
    curl -s --cookie /tmp/qbittorrent-cookie.txt -X POST "http://localhost:8080/api/v2/torrents/delete" -d "hashes=\$torrent_id"
}
EOL

# === Generate Plex Client Script ===
cat <<EOL > /home/$USER/plex_client.sh
#!/bin/bash

source /home/$USER/config.sh

# Function to make Plex API requests
plex_request() {
    local endpoint=\$1
    local method=\${2:-GET}

    curl -s -X \$method "\$PLEX_URL\$endpoint" -H "X-Plex-Token: \$PLEX_TOKEN"
}

# Function to scan a library
scan_library() {
    local library_name=\$1
    plex_request "/library/sections/\$library_name/refresh" POST
}

# Function to reboot Plex
reboot_plex() {
    sudo systemctl restart plexmediaserver
    echo "Plex Media Server is restarting."
}
EOL

# === Generate Telegram Bot Script ===
cat <<EOL > /home/$USER/telegram_bot.sh
#!/bin/bash

source /home/$USER/config.sh
source /home/$USER/qbit_client.sh
source /home/$USER/plex_client.sh

# Function to handle Telegram commands
handle_command() {
    local chat_id=\$1
    local command=\$2
    local args=\$3

    case "\$command" in
        "/start")
            send_message "\$chat_id" "Welcome to the Torrent Bot! Send a magnet link to start downloading."
            ;;
        "/complete")
            local torrent_id=\$(echo \$args | cut -d ' ' -f 1)
            local category=\$(echo \$args | cut -d ' ' -f 2)
            if [[ " \${PLEX_CATEGORIES[@]} " =~ " \$category " ]]; then
                move_to_category "\$torrent_id" "\$category"
                send_message "\$chat_id" "Files moved to \${CATEGORIES_PATH}/\$category"
            else
                send_message "\$chat_id" "Invalid category. Available categories: \${PLEX_CATEGORIES[@]}"
            fi
            ;;
        "/plex_scan")
            local library_name=\$args
            scan_library "\$library_name"
            send_message "\$chat_id" "Scanning library \$library_name."
            ;;
        "/plex_reboot")
            reboot_plex
            send_message "\$chat_id" "Plex Media Server is rebooting."
            ;;
        *)
            if [[ \$command == "magnet:"* ]]; then
                local category=\$args
                if [[ " \${PLEX_CATEGORIES[@]} " =~ " \$category " ]]; then
                    torrent_id=\$(add_torrent "\$command" "\$category")
                    send_message "\$chat_id" "Download started. Torrent ID: \$torrent_id"
                else
                    send_message "\$chat_id" "Invalid category. Available categories: \${PLEX_CATEGORIES[@]}"
                fi
            else
                send_message "\$chat_id" "Unknown command or magnet link."
            fi
            ;;
    esac
}

# Function to send message to Telegram
send_message() {
    local chat_id=\$1
    local text=\$2

    curl -s -X POST "https://api.telegram.org/bot\$TELEGRAM_TOKEN/sendMessage" -d "chat_id=\$chat_id&text=\$text"
}

# Main loop to handle Telegram updates
offset=0
while true; do
    response=\$(curl -s -X GET "https://api.telegram.org/bot\$TELEGRAM_TOKEN/getUpdates?offset=\$offset")
    updates=\$(echo \$response | jq -c '.result[]')
    for update in \$updates; do
        update_id=\$(echo \$update | jq -r '.update_id')
        chat_id=\$(echo \$update | jq -r '.message.chat.id')
        text=\$(echo \$update | jq -r '.message.text')
        command=\$(echo \$text | cut -d ' ' -f 1)
        args=\$(echo \$text | cut -d ' ' -f 2-)

        handle_command "\$chat_id" "\$command" "\$args"

        offset=\$((update_id + 1))
    done
    sleep 1
done
EOL

# === Make Scripts Executable ===
chmod +x /home/$USER/config.sh /home/$USER/qbit_client.sh /home/$USER/plex_client.sh /home/$USER/telegram_bot.sh

# === Start the Telegram Bot ===
/home/$USER/telegram_bot.sh
