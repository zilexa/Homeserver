#!/bin/bash
## Before you run this script, your filesystem and folder structures need to be installed and configured !!
## After you run this script, you can run docker-compose.yml and enjoy your server!
#
# See https://github.com/zilexa/Homeserver
# tba: snapraid-btrfs
# tba: config of nightly scripts
# tba: backup script
# tba: syncthing-backup script (not finished yet)

# ____________________
# Install server tools
# ____________________
# SSH
sudo apt -y install ssh
sudo systemctl enable --now ssh
# firewall of Ubuntu is disabled by default, I keep it like that but do add the rule in case fw is activated in the future.
sudo ufw allow ssh 

# Install lm-sensors
sudo apt install lm-sensors
sudo sensors-detect --auto

# Install Powertop
sudo apt -y install powertop
# Create a service file to run powertop --auto-tune at boot
sudo tee -a /etc/systemd/system/powertop.service << EOF
[Unit]
Description=PowerTOP auto tune

[Service]
Type=idle
Environment="TERM=dumb"
ExecStart=/usr/sbin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable powertop.service
# Tune system now
sudo powertop --auto-tune

# NFS Server - 15%-30% faster than SAMBA/SMB shares
sudo apt -y install nfs-server
read -p "for further instructions to enable NFSv4.2 go to https://github.com/zilexa/Homeserver/blob/master/NetworkFileSystem/NFSv4.2-How-To.md"

# PiVPN ~ Install & configure wizard
curl -L https://install.pivpn.io | bash  

# Netdata ~ install wizard
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# ______________________________________________________________
# Install Docker 
# --------------------------------------------------------------
# Install Docker, Docker-Compose and bash completion for Compose
wget -qO - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt -y update
sudo apt -y install docker-ce docker-ce-cli containerd.io
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo curl -L https://raw.githubusercontent.com/docker/compose/1.26.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

# ______________________________________________________________
# Configure Docker
# --------------------------------------------------------------
# Make docker-compose file an executable file and add the current user to the docker container
sudo chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker ${USER}

# Create the docker folder
sudo mkdir -p $HOME/docker
sudo setfacl -Rdm g:docker:rwx ~/docker
sudo chmod -R 755 ~/docker
# Get environment variables to be used by Docker (i.e. requires TZ in quotes)
sudo wget -P $HOME/docker https://raw.githubusercontent.com/zilexa/Homeserver/master/.env

# Get docker compose file
sudo wget -P $HOME/docker https://raw.githubusercontent.com/zilexa/Homeserver/master/docker-compose.yml


# __________________________________________________________________________________
# Docker per-application configuration, required before starting the apps container
# ----------------------------------------------------------------------------------
# HTTPS reverse proxy: Traefik ~ Create Traefik files and set permissions
sudo mkdir -p $HOME/docker/traefik
sudo touch $HOME/docker/traefik/traefik.log
sudo chmod 600 $HOME/docker/traefik/traefik.log
sudo touch $HOME/docker/traefik/acme.json
sudo chmod 600 $HOME/docker/traefik/acme.json
# Download Traefik settings
sudo wget -P $HOME/docker/traefik https://raw.githubusercontent.com/zilexa/Mediaserver/master/traefik/traefik.toml

# Firefox Sync ~ Generate secret
# ------------------------------------------------
sudo mkdir -p $HOME/docker/firefox-syncserver/secret
sudo touch $HOME/docker/firefox-syncserver/secret/secret.txt
sudo head -c 20 /dev/urandom | sha1sum | awk '{print $1}' >> $HOME/docker/firefox-syncserver/secret/secret.txt

# FileRun & ElasticSearch ~ requirements
# ---------------------------------------------
# Create folder and set permissions
sudo mkdir -p $HOME/docker/filerun/esearch
sudo chown -R $USER:$USER $HOME/docker/filerun/esearch
sudo chmod 777 $HOME/docker/filerun/esearch
# IMPORTANT! Should be the same user:group as the owner of the personal data you access via FileRun!
sudo mkdir -p $HOME/docker/html
sudo chown -R $USER:$USER $HOME/docker/html
sudo chmod 755 $HOME/docker/filerun/esearch
# Change OS virtual mem allocation as it is too low by default for ElasticSearch
sudo sysctl -w vm.max_map_count=262144
# Make this change permanent
sudo sh -c "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf"

# Required on Ubuntu systems if you will run your own DNS resolver and/or adblocking DNS server.
# ---------------------------------------------
sudo systemctl disable systemd-resolved.service
sudo systemctl stop systemd-resolved.service
echo "dns=default" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
echo "Move dns=default to the [MAIN] section by manually deleting it and typing it. Hit CTRL+O to save, CTRL+X to exit and continue."
read -p "ready to do this? Hit a key..."
sudo nano /etc/NetworkManager/NetworkManager.conf
sudo rm /etc/resolv.conf
sudo systemctl restart NetworkManager.service
