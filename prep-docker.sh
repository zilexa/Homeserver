## Required actions before running docker-compose.yml
# See https://github.com/zilexa/Homeserver
#!/bin/bash
#Set environment variables to be used by Docker (i.e. requires TZ in quotes)
#Also used for secrets to be filled in by the user (required vars created without value)
echo PUID=1000 >> $HOME/docker/vars.env
echo PGID=1000 >> $HOME/docker/vars.env
echo TZ='"'$TZ'"' >> $HOME/docker/vars.env
echo >> $HOME/docker/vars.env
echo PW_PIHOLE= >> $HOME/docker/vars.env
echo >> $HOME/docker/vars.env
PW_ROOT_MYSQL= >> $HOME/docker/vars.env
USER_MYSQL= >> $HOME/docker/vars.env
PW_MYSQL= >> $HOME/docker/vars.env
echo >> $HOME/docker/vars.env
DOMAIN= >> $HOME/docker/vars.env
echo >> $HOME/docker/vars.env
$USER_VPN= >> $HOME/docker/vars.env
$PW_VPN= >> $HOME/docker/vars.env
echo >> $HOME/docker/vars.env
PW_MEDIA= >> $HOME/docker/vars.env

# Create PiHole log file
mkdir -p ${USERDIR}/docker/pihole/var-log
touch ${USERDIR}/docker/pihole/var-log/pihole.log

# Create Traefik files and set permissions
mkdir -p ${USERDIR}/docker/traefik
touch $USERDIR/docker/traefik/traefik.log
chmod 600 $USERDIR/docker/traefik/traefik.log
touch ${USERDIR}/docker/traefik/acme.json
chmod 600 $USERDIR/docker/traefik/acme.json
# Download Traefik settings
wget -P $USERDIR/docker/traefik https://raw.githubusercontent.com/zilexa/Mediaserver/master/traefik/traefik.toml

# Create Firefox-Syncserver file & generate secret
mkdir -p ${USERDIR}/docker/firefox-syncserver/secret
touch $USERDIR/docker/firefox-syncserver/secret/secret.txt
head -c 20 /dev/urandom | sha1sum | awk '{print $1}' >> $USERDIR/docker/firefox-syncserver/secret/secret.txt

# Requirement for FileRun, ElasticSearch (= additional container required by FileRun to search by text within files)
# Create folder and set permissions
mkdir -p ${USERDIR}/docker/filerun/esearch
sudo chown -R $USER:$USER ${USERDIR}/docker/filerun/esearch
sudo chmod 777 ${USERDIR}/docker/filerun/esearch
# Change OS virtual mem allocation as it is too low by default for ElasticSearch
sudo sysctl -w vm.max_map_count=262144
# Make this change permanent
sudo sh -c "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf"
