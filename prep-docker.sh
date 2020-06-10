## Required actions before running docker-compose.yml
# See https://github.com/zilexa/Homeserver
# Run this script with sudo -i to inherit the correct env variables ($HOME should be home/user instead of home/root)
#!/bin/bash
#Set environment variables to be used by Docker (i.e. requires TZ in quotes)
wget -P $HOME/docker https://raw.githubusercontent.com/zilexa/Homeserver/master/.env

# Create PiHole log file
mkdir -p $HOME/docker/pihole/var-log
touch $HOME/docker/pihole/var-log/pihole.log

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
cd $HOME/docker
wget https://github.com/stefanprodan/dockprom/archive/master.zip
unzip master.zip
mv dockprom-master/grafana $HOME/docker
mv dockprom-master/prometheus $HOME/docker
rm -r dockprom-master
rm -r master.zip

