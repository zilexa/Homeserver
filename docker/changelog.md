# CHANGELOG 2022-04-22
# ADDED: labels to every non-exposed container to allow access each service via its own local subdomain. Please add these domains to your AdGuard Home>Settings>DNS Rewrites
# ADDED: labels added to every container with a UI to populate a simple startpage (by flame container)
# ADDED: Added Flame, a nice startpage. access via IP:5005 or http://start.o, go to settings, enable docker to show all services with the flame labels. 
# REMOVED: Per-category docker bridge networks, since all containers with a UI require to be in the web-proxy network for subdomain access.
#
# CHANGELOG 2022-04-11
# UPDATED: Hotio images have a new source. 
# CHANGED: For all services, first item is container_name, second is image source.  
#
# CHANGELOG 2022-04-08
# UPDATED: Now works with all latest containers. 
# CHANGED: 'true' to true everywhere.
# CHANGED: CADDY-DOCKER-PROXY: renamed contaimer name:'caddy-proxy to 'web-proxy', its network (unchanged) has the same name. 
# CHANGED: CADDY-DOCKER-PROXY: latest version requires an env variable, this has been added.
# CHANGED: CADDY-DOCKER-PROXY: requires you to run "docker network create web-proxy" BEFORE running compose!
#  
# CHANGELOG 2021-05-15
# CHANGED: Bitwarden_rs has been renamed by the developer to Vaultwarden, renamed the image, volume path, env variable
#
# CHANGELOG 2021-05-01
# REMOVED: PULLIO notify labels. It cannot send email notifications, only Discord which I and most people I believe don't use. 
## KEPT: PULLIO update labels, for media/download related containers, to update all of them with 1 command (manually or scheduled). 
# CHANGED: Scrutiny, an attempt to disable its interval based SMART scan, so that this can be done via the NIGHTLY, script.
## REASON: It will spin up all drives just for the SMART scan. Better to do this when they are already spinning. 
# CLEANUP: Changed order of values, to have consistency for each and every container.
#
# CHANGELOG 2021-04-28
## REMOVED: Watchtower. Replaced with Pullio bash script. For a weekly update check, running a daemon like Watchtower makes no sense. 
## CHANGED: VPN-proxy back to Frankfurt, for some reason Swiss doesn't work, the server TLS certificate is outdated. 
## REPLACED IMAGE: QBittorrent image with the one from Hotio because it has unrar and doesn't create files with root-only access.
## REPLACED ALL MEDIA RELATED IMAGES: all images are now from Hotio.
## CHANGED: Scrutiny requires a yaml config file to recognise NVME drives. see my github for an example. 
## CHANGED: Ports of VPN-proxy to allow access to QBittorrent as it listens on a different port for the webUI.  
#
# CHANGELOG 2021-04-13
## ADDED Guacamole! Now you can open your browser and access the desktop of your server. The image works, still have to test Guacamole. 
## Removed Transmission as nobody seems to use it anymore, even though it had full Sonarr compatibility, it is riddled with config issues:
## temp folder will never be used with Sonarr/Radarr, making the filesystem optimisations (disabling CoW & seperate subvolume for incomplete dir)
## Completely useless, allowing fragmentation. Also, the complete dir is changed during downloading via Sonarr. Devs believe this is all normal behaviour.
## ADDED QBittorrent, not from Linuxserver as it is 360MB versus this 150MB image. 
## ToDO: Will look into using Hotio QFlood image instead, the UI is much nicer but seems to lack important settings to increase disk cache etc.
## REMOVED unneccessary port binds: 80 for Caddy is not used. Now used for Organizr to access server homepage via url (use your servers /etc/hosts file to set an url). 
## ToDO: Will look into registering https for LAN only, to access all services via https organizr url (not sure if it makes sense to go this far). 
## CHANGED: pia wireguard vpn to swiss instead of nine eyes Germany.
## NOTE: I stopped using Syncthing due to this issue (my laptop SSD filled up within 30min): https://forum.syncthing.net/t/problems-with-renamed-directory/16611
## I might try Resilio instead or see if the dev is helpful to figure out the issue, if it isn't "by design".
