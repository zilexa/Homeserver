TBA


1) **Server Management & Monitoring**
_Netdata_
via Docker: no but possible, probably more difficult. 
monitoring of system resources, temperature, storage, memory as well as per-docker container resource info. 
There are other more bloated alternatives (Prometheus+Grafana) that is overkill in a homeserver situation. Netdata requires lm-sensors. 
_Portainer_
a Docker webUI to manage and update containers. Basically a ui of the Docker command. 
_Organizr_
A a customisable homepage to have quick access to all your services/applications. 


**Category 2: User Privacy & Network Security**
_Traefik_
reverse-proxy for HTTPS access to the services that you want to expose online. Takes care of certification renewal etc. Pretty complicated. Spend lots of time figuring it out. I want to replace Traefik for Caddy soon. 
_PiVPN_
Using the Wireguard VPN protocol, easy and secure access to non-exposed services and to your server (via SSH).
I highly recommend to use it for DNS & homeserver access by default. All other traffic can bypass the server unless you are connected to unsafe networks (public networks or countries that do not respect privacy). 
_AdGuard Home & Unbound_
Unbound is a recursive DNS resolver. By using Unbound, not 1 ISP and DNS company will know the full URLs of the sites you are visiting. 
AdGuard Home is a DNS based malware & ad filter. No more ads, malware, coinmining, phishing. All devices on your homenetwork are ad-free and protected. 
Can also be used remotely via split tunnel VPN. 
_UniFi Controller_
Ubiquiti UniFi wireless access points are the best. Recommended for good WiFi in your home. If you don't use their access points you do not need this. If you do have their APs, this is only needed to setup once. 

**Category 3: Cloud Experience**
_FileRun and/or NextCloud_
FileRun is a very fast, lightweight and feature-rich selfhosted alternative to Dropbox/GoogleDrive/OneDrive. It always shows the realtime state of your filesystem. 
It is not open-source and the free version allows 10 users only. I use it for myself and direct family/friends only. It has no other features: purely a "drive". It does support WebDAV. 
NextCloud is a similar solution and very popular, open-source and free to use. Though not as fast as FileRun, there are no limits plus it has a plethora of other functionalities such as Calendar, Contacts and much more. 
_OnlyOffice_
Your own selfhosted Google Docs/Office365 alternative! This works well with both FileRun and NextCloud. 
_Syncthing_
FileRun and NextCloud are great, they allow you to sync your phone/devices to your server via the WebDAV protocol --> that is not ideal or fast. 
Syncthing is build for 1 thing only: secure and fast 2-way syncing. It uses its own protocol. It is extremely fast and robust. On Android, the Syncthing-fork application allows you to easily add your Whatsapp, Signal and other apps backups and photos, camera etc to sync. Always or when charging/when on wifi. 
_Firefox Sync_
The web has become a dangerous monopoly with only 3 browser engines: Chrome, Safari and Firefox. Without Firefox, there is little competition and transparency left. By running your own Firefox Sync server, all your history, bookmarks, cookies, logins of Firefox on all your devices (phones, tablets, laptops) can be synced with your own server instead of Mozilla. Compare this to Google Chrome syncing to your Google Account or Safari syncing to iCloud. It also means you have a backup of your browser profile. This tool has been provided by Mozilla. 

**Category 4: TV media**
_Jellyfin_
A mediaserver to serve clients (Web, Android, iOS, iPadOS, Tizen, LG WebOS, Windows) your tvshows, movies and music in a slick and easy to use interface just like the famous streaming giants do. Jellyfin is userfriendly and has easy features that you might miss from the streaming giants such as watched status management etc. 
The mediaserver can transcode media on the fly to your clients, adjusting for available bandwith. It can use hardware encoding capabilities of your server.
|Service| Description  | Rationale 
_Sonarr, Radarr, Bazarr, Jackett_ 
See: https://wiki.servarr.com/Docker_Guide
A visual, user-friendly tool allowing you to search & add your favourite TV shows (Sonarr) or Movies (Radarr) and subtitles (Bazarr), see a schedule of when the next episodes will air and completely take care of obtaining the requires files (by searching magnets/torrents via Jackett, a proxy for all torrentsites) and organising them, all in order to get a full-blown Nextflix experience served by JellyFin.| For years I have messed with FlexGet, but it can't beat Sonarr.   
_Transmission + PIA Wireguard VPN_ 
Sonarr, Radarr, Jackett (automatically) add stuff to Transmission which is a p2p client. It should run behind the chosen VPN provider.Many alternatives. Transmission is lightweight and originally has a bit better integration with the tools mentioned + allows for port change via the VPN provider.  
Via the PIA Wireguard VPN docker image, your downloads are obscured while still allowing you to reach high speeds via the open port in the VPN tunnel. 
