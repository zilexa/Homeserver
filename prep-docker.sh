## Required actions before running docker-compose.yml
# See https://github.com/zilexa/Homeserver
#!/bin/bash
#Set environment variables to be used by Docker (i.e. requires TZ in quotes)
sudo sh -c "echo USERHOME=/home/$LOGNAME >> /etc/environment"
wget -P $USERHOME/docker https://raw.githubusercontent.com/zilexa/Homeserver/master/.env

# Create PiHole log file
mkdir -p $USERHOME/docker/pihole/var-log
touch $USERHOME/docker/pihole/var-log/pihole.log

# Create Traefik files and set permissions
mkdir -p $USERHOME/docker/traefik
touch $USERHOME/docker/traefik/traefik.log
chmod 600 $USERHOME/docker/traefik/traefik.log
touch $USERHOME/docker/traefik/acme.json
chmod 600 $USERHOME/docker/traefik/acme.json
# Download Traefik settings
wget -P $USERHOME/docker/traefik https://raw.githubusercontent.com/zilexa/Mediaserver/master/traefik/traefik.toml

# Create Firefox-Syncserver file & generate secret
mkdir -p $USERHOME/docker/firefox-syncserver/secret
touch $USERHOME/docker/firefox-syncserver/secret/secret.txt
head -c 20 /dev/urandom | sha1sum | awk '{print $1}' >> $HOME/docker/firefox-syncserver/secret/secret.txt

# Requirement for FileRun, ElasticSearch (= additional container required by FileRun to search by text within files)
# Create folder and set permissions
mkdir -p $USERHOME/docker/filerun/esearch
sudo chown -R $USER:$USER $USERHOME/docker/filerun/esearch
sudo chmod 777 $USERHOME/docker/filerun/esearch
# Change OS virtual mem allocation as it is too low by default for ElasticSearch
sudo sysctl -w vm.max_map_count=262144
# Make this change permanent
sudo sh -c "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf"
