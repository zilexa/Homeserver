## Required actions before running docker-compose.yml
#!/bin/bash
# Create PiHole log file
mkdir -p ${USERDIR}/docker/pihole/var-log
touch ${USERDIR}/docker/pihole/var-log/pihole.log

# Create Traefik files
mkdir -p ${USERDIR}/docker/traefik
touch $USERDIR/docker/traefik/traefik.log
touch ${USERDIR}/docker/traefik/acme.json
chmod 600 $USERDIR/docker/traefik/acme.json
wget -P $USERDIR/docker/traefik https://raw.githubusercontent.com/zilexa/Mediaserver/master/traefik/traefik.toml

# Create Firefox-Syncserver file & generate secret
mkdir -p ${USERDIR}/docker/firefox-syncserver/secret
touch $USERDIR/docker/firefox-syncserver/secret/secret.txt
cho "[syncserver]" >> $USERDIR/docker/firefox-syncserver/secret/secret.txt
head -c 20 /dev/urandom | sha1sum | awk '{print $1}' >> $USERDIR/docker/firefox-syncserver/secret/secret.txt
