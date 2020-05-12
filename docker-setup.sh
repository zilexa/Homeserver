## Required actions before running docker-compose.yml
#
# Create PiHole log file
touch ${USERDIR}/docker/pihole/var-log/pihole.log
#
# Create Traefik files
touch $USERDIR/docker/traefik/traefik.log
touch ${USERDIR}/docker/traefik/acme.json
chmod 600 $USERDIR/docker/traefik/acme.json
wget blabla

