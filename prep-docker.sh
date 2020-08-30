#!/bin/bash
## Required actions before running docker-compose.yml
# See https://github.com/zilexa/Homeserver
# Run this script with sudo -E to make sure $HOME points to /home/username instead of /root
#
# Install Docker, Docker-Compose and bash completion for Compose
wget -qO - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt -y update
sudo apt -y install docker-ce docker-ce-cli containerd.io
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo curl -L https://raw.githubusercontent.com/docker/compose/1.26.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

# Make docker-compose file an executable file and add the current user to the docker container
sudo chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker ${USER}

# Create the docker folder
mkdir -p $HOME/docker
# Get environment variables to be used by Docker (i.e. requires TZ in quotes)
wget -P $HOME/docker https://raw.githubusercontent.com/zilexa/Homeserver/master/.env

# Get docker compose file
wget -P $HOME/docker https://raw.githubusercontent.com/zilexa/Homeserver/master/docker-compose.yml

# Create PiHole log file
mkdir -p $HOME/docker/pihole/var-log
touch $HOME/docker/pihole/var-log/pihole.log

# Requirements to run PiHole docker on Ubuntu
sudo systemctl disable systemd-resolved.service
sudo systemctl stop systemd-resolved.service
echo "add dns=default under [main] then hit CTRL+O (to save) and CTRL+X (to exit file editor)"
read -p "remember the above and hit a key when you are ready to do it..."
sudo nano /etc/NetworkManager/NetworkManager.conf
# if you still have issues, remove /etc/resolv.conf (auto-generated), the backup file is still available.
sudo mv /etc/resolv.conf /etc/resolv.conf.bak
sudo service network-manager restart

# Create Traefik files and set permissions
mkdir -p $HOME/docker/traefik
touch $HOME/docker/traefik/traefik.log
chmod 600 $HOME/docker/traefik/traefik.log
touch $HOME/docker/traefik/acme.json
chmod 600 $HOME/docker/traefik/acme.json
# Download Traefik settings
wget -P $HOME/docker/traefik https://raw.githubusercontent.com/zilexa/Mediaserver/master/traefik/traefik.toml

# Create Firefox-Syncserver file & generate secret
mkdir -p $HOME/docker/firefox-syncserver/secret
touch $HOME/docker/firefox-syncserver/secret/secret.txt
head -c 20 /dev/urandom | sha1sum | awk '{print $1}' >> $HOME/docker/firefox-syncserver/secret/secret.txt

# Requirement for FileRun, ElasticSearch (= additional container required by FileRun to search by text within files)
# Create folder and set permissions
mkdir -p $HOME/docker/filerun/esearch
chown -R $USER:$USER $HOME/docker/filerun/esearch
chmod 777 $HOME/docker/filerun/esearch
# Change OS virtual mem allocation as it is too low by default for ElasticSearch
sysctl -w vm.max_map_count=262144
# Make this change permanent
sh -c "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf"

# Get config files for monitoring via Prometheus and Grafana
# cd $HOME/docker
# wget https://github.com/stefanprodan/dockprom/archive/master.zip
# unzip master.zip
# mv dockprom-master/grafana $HOME/docker
# mv dockprom-master/prometheus $HOME/docker
# rm -r dockprom-master
# rm -r master.zip

