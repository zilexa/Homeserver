## Required actions before running docker-compose.yml
#!/bin/bash
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
# echo "[syncserver]" >> $USERDIR/docker/firefox-syncserver/secret/secret.txt # file should only contain secret contrary to mozilla doc
head -c 20 /dev/urandom | sha1sum | awk '{print $1}' >> $USERDIR/docker/firefox-syncserver/secret/secret.txt

# Requirement for ElasticSearch (= additional container required by FileRun to search by text within files)
# Create folder and set permissions
mkdir -p ${USERDIR}/docker/filerun/esearch
sudo chown -R $USER:$USER ${USERDIR}/docker/filerun/esearch
sudo chmod 777 ${USERDIR}/docker/filerun/esearch
# Change OS virtual mem allocation as it is too low by default for ElasticSearch
sudo sysctl -w vm.max_map_count=262144
# Make this change permanent
sudo sh -c "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf"
