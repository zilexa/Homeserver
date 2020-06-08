## Required actions before running docker-compose.yml
# See https://github.com/zilexa/Homeserver
#!/bin/bash
# Create a system-wide environmental variable that will always point to the home folder of the logged in user
# required because $HOME cannot be user, it will point to the homedir of root when using SUDO or to the logged in user when not using SUDO.
sudo sh -c "echo USERHOME=/home/$LOGNAME >> /etc/environment"
#Set environment variables to be used by Docker (i.e. requires TZ in quotes)
wget -P $HOMEUSER/docker https://raw.githubusercontent.com/zilexa/Homeserver/master/.env

# Create PiHole log file
mkdir -p $HOMEUSER/docker/pihole/var-log
touch $HOMEUSER/docker/pihole/var-log/pihole.log

# Create Traefik files and set permissions
mkdir -p $HOMEUSER/docker/traefik
touch $HOMEUSER/docker/traefik/traefik.log
chmod 600 $HOMEUSER/docker/traefik/traefik.log
touch $HOMEUSER/docker/traefik/acme.json
chmod 600 $HOMEUSER/docker/traefik/acme.json
# Download Traefik settings
wget -P $HOMEUSER/docker/traefik https://raw.githubusercontent.com/zilexa/Mediaserver/master/traefik/traefik.toml

# Create Firefox-Syncserver file & generate secret
mkdir -p $HOMEUSER/docker/firefox-syncserver/secret
touch $HOMEUSER/docker/firefox-syncserver/secret/secret.txt
head -c 20 /dev/urandom | sha1sum | awk '{print $1}' >> $HOME/docker/firefox-syncserver/secret/secret.txt

# Requirement for FileRun, ElasticSearch (= additional container required by FileRun to search by text within files)
# Create folder and set permissions
mkdir -p $HOMEUSER/docker/filerun/esearch
sudo chown -R $USER:$USER $HOMEUSER/docker/filerun/esearch
sudo chmod 777 $HOMEUSER/docker/filerun/esearch
# Change OS virtual mem allocation as it is too low by default for ElasticSearch
sudo sysctl -w vm.max_map_count=262144
# Make this change permanent
sudo sh -c "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf"
