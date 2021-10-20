## Overview of applications and services

Almost everything will run isolated in [Docker containers](https://www.docker.com/resources/what-container). The setup is easy with the provided docker-compose.yml file, which is a declarative way to pull the images from the internet, create containers and configure everything with a single command! See the [subguide for Docker Compose](https://github.com/zilexa/Homeserver/tree/master/docker) on how to get up and running, **this is the unique part of this guide, a complete and carefully built working Docker-Compose.yml file with variables.** and the correct, well-maintained docker images have been selected, sometimes you spend hours finding the right one as there are often multiple available. 

You can easily find other applications via https://hub.docker.com/
Below a description of each application that are in Docker-Compose.yml. Choose the ones you need.
The only exceptions -apps that run natively on the OS for specific reasons- are Netdata, PiVPN and AdGuard Home. These apps have very easy installation instructions.


### _Server Management & Monitoring_
_Server Monitoring via [Netdata](https://learn.netdata.cloud/docs/overview/what-is-netdata)_
Note this is installed natively on your OS: [Native Install](https://learn.netdata.cloud/docs/agent/packaging/installer)
>Monitoring of system resources, temperature, storage, memory as well as per-docker container resource info.\
>There are other more bloated alternatives (Prometheus+Grafana) that is overkill in a homeserver situation. Netdata requires lm-sensors.\
>Runs natively just because it is such a deeply integrated to get sensor access etc. If you run it in Docker, you might have to fix that access yourself.

\
_Container management via [Portainer](https://www.portainer.io/products/community-edition)_ 
>An complete overview of your containers and related elements in a nice visual UI, allowing you to easily check the status, inspect issues, stop, restart, update or remove containers that you launched via Docker Compose. Strangely, the tool cannot inform you of updates.

\
_Server Applications Portal via [Organizr](https://github.com/causefx/Organizr)_
>A customisable homepage to have quick access to all your services/applications. 

\
_Home WiFi configuration via [UniFi Controller](https://github.com/goofball222/unifi)_
Mobile App: [Unifi Network](https://play.google.com/store/apps/details?id=com.ubnt.easyunifi)
> Only if you use Ubiqity/UniFi hardware. Ubiquiti UniFi wireless access points are the best and are easy to seamlessly integrate in your house decoration. Note there are lots of alternatives these days. 
> Recommended for good WiFi in your home. If you don't use their access points you do not need this. If you do have their APs, this is only needed to setup once, no need to keep it running all the time. 

### _Web Access Security_

_Secure Web Proxy via [docker caddy proxy](https://github.com/lucaslorentz/caddy-docker-proxy)_
>reverse-proxy for HTTPS access to the services that you want to expose online. Takes care of certification renewal etc.\
>Caddy already extremely simplifies the whole https process to allow browsers and apps A+ secure connection to your server. Docker Caddy Proxy goes one step further and allows you to set it up per container with just 2 lines! Alternatives like Traefik are needlessly complicated.

> By default only the password manager (Bitwarden), file+Office cloud (FileRun, OnlyOffice), Firefox Sync server and Syncthing are accessible via web.\
> All other apps are only available via VPN or within your local network. You can easily expose other apps such as Jellyfin by adding a few labels to its container. 

\
_Safe browsing ad- and malware free [AdGuardHome](https://adguard.com/en/adguard-home/overview.html)_ 
_Your own recursive DNS server to stop shouting your browsing history to the world [Unbound](https://github.com/MatthewVance/unbound-docker)_ 
>Unbound is a recursive DNS resolver. By using Unbound, no 3rd party will know the full URLs of the sites you are visiting (your ISP, local and international DNS providers).\
>AdGuardHome is a DNS based malware & ad filter, blocking ad requests but also blocking known malware, coinmining and phishing sites!

>After AGH filters the requests, the remaining DNS requests are forwarded to Unbound, which chops it up in pieces and contacts the end-point DNS providers to get the necessary IP for you to visit the site.\
>This way, not 1 company in the world has your complete DNS requests. Compare this to the hyped encrypted DNS (DoH): your request is decrypted at the provider, the provider and all end-point DNS providers see your un-encrypted request.

>By blocking on DNS request level, you easily block 5-15% of internet traffic requests, significantly reducing the data needed to load websites, run apps and play games.\
>All devices connected to your router such as home speakers, smart devices, mediaplayer etc are automatically protected.\
>This setup can also be used used remotely via split tunnel VPN (see PiVPN). This means you have 1 adfiltering and DNS resolver for all devices, anywhere in the world.


### _Cloud Experience_
_Remote VPN access [vpn-server-ui](https://github.com/vx3r/wg-gen-web/)_ - via Docker\
> Notice your container vpn-server-ui (http://serverip:5100). Create an admin account, then add VPN profiles for all your devices.\  
> For Android: install Wireguard on your dev and consider installing Automate (free). Read my post about why and how here: https://www.reddit.com/r/WireGuard/comments/nkn45n/on_android_finally_you_can_automatically_turn/ 

_Password Manager [Vaultwarden](https://github.com/dani-garcia/vaultwarden)_ - via Docker\
Mobile App: [Bitwarden](https://play.google.com/store/apps/details?id=com.x8bit.bitwarden)
> Easily the best, user friendly password manager out there. Open source and therefore fully audited to be secure. The mobile apps are extremely easy to use.\
> Additionally allows you to securely share passwords and personal files or documents (IDs, salary slips, insurance) with others via Bitwarden Send.\
> By using `bitwarden_rs`, written in the modern language RUST, it uses exponentially less resources than the conventional Bitwarden-server.

\
_Files cloud [FileRun](https://filerun.com/)_ instead of NextCloud - via Docker\
Mobile Apps: [CX File Explorer](https://play.google.com/store/apps/details?id=com.cxinventor.file.explorer) and [FolderSync](https://play.google.com/store/apps/details?id=dk.tacit.android.foldersync.lite) (for phone backup).
>FileRun is a very fast, lightweight and feature-rich selfhosted alternative to Dropbox/GoogleDrive/OneDrive. Nextcloud, being much slower and overloaded with additional apps, can't compete on speed and user-friendliness. Also, with FileRun each user has a dedicated folder on your server and unlike Nextcloud, FileRun does not need to periodically scan your filesystem for changes.\
> FileRun support WebDAV, ElasticSeach for in-file search, extremely fast scrolling through large photo albums, encryption, guest users, shortened sharing links etc.\
>Limits compared to Nextcloud: It is not open-source and the free version allows 10 users only. I use it for myself and direct family/friends only. It has no calendar/contacts/calls etc features like Nextcloud.

> The Nextcloud mobile app works with FileRun but CX File Explorer (4.8 stars) is so much better and easier to use. It is a swift and friendly Android file manager that allows you to add your FileRun instance via WebDAV. Compared to the Nextcloud app, it allows you to easily switch between your local storage and your cloud, copying files betweeen them.\

> FolderSync is THE app for Android when you run your own filecloud, allowing you to sync the data of your apps (photos, chat apps, backup of your 2FA app (Aegis), home screen settings etc.) to your server, instead of to Google Drive. It also allows local sync: moving all app-specific backup files (like whatsapp\databases) to a single backup dir first before syncing it to your server.

*Sync devices, external users laptops*
- Filerun supports webDAV, see [helpful tips](https://docs.filerun.com/webdav). This way you benefit from instant file indexing (for search) and server-side photo thumbails & previews. Consider using webDAV to sync your User files with your mobile devices: [CX File Explorer](https://play.google.com/store/apps/details?id=com.cxinventor.file.explorer) is very user-friendly, additionally [FolderSync](https://www.tacit.dk/) allows instant or scheduled syncing. 
- For desktops and laptops and to keep your parents PC user files in-sync, consider webDAV as well. For Linux, the NextCloud Desktop client is the obvious choice as it is the only tool that does 2-way sync.
- Alternatively, [Setup NFS](https://github.com/zilexa/Homeserver/tree/master/network%20share%20(NFSv4.2)) a zero-overhead solution used in datacenters, the fastest way to share files/folders with other devices (laptops/PCs) via your local home network.

\
_Your own Office Online/Google Docs via FileRun [OnlyOffice DocumentServer](https://www.onlyoffice.com/office-suite.aspx?from=default)_ - via Docker
>Your own selfhosted Google Docs/Office365 alternative! This works well with both FileRun and NextCloud.

\
_Your own browser sync engine [Firefox Sync](https://github.com/mozilla-services/syncserver)_ - via Docker
>By running your own Firefox Sync server, all your history, bookmarks, cookies, logins of Firefox on all your devices (phones, tablets, laptops) can be synced with your own server instead of Mozilla.\
>Compare this to Google Chrome syncing to your Google Account or Safari syncing to iCloud. It also means you have a backup of your browser profile. This tool has been provided by Mozilla. This is the only browser that allows you to use your own server to sync your browser account!

\
_Paper document management [Paperless](https://github.com/jonaswinkler/paperless-ng)_ - via Docker
>Scan files and auto-organise for your administration archive with a webUI to see and manage them. [Background](https://blog.kilian.io/paperless/) of Paperless. No more paper archives!


### _Media Server_
_Media server [Jellyfin](https://jellyfin.org/)_ - via Docker\
Mobile & TV Apps: [Jellyfin clients](https://jellyfin.org/clients/) (for series/movies), [Gelli](https://github.com/dkanada/gelli/releases) (amazing Music Player)
>A mediaserver to serve clients (Web, Android, iOS, iPadOS, Tizen, LG WebOS, Windows) your tvshows, movies and music in a slick and easy to use interface just like the famous streaming giants do.\
>Jellyfin is user-friendly and has easy features that you might miss from the streaming giants such as watched status management etc.\
The mediaserver can transcode media on the fly to your clients, adjusting for available bandwith. It can use hardware encoding capabilities of your server.\
> By using the Gelli app, Jellyfin competes with music servers such as SubSonic/AirSonic. Gelli is more slick and in active development.\
> Allows you to listen to your old AudioCDs! A HiRes Audio alternative to Spotify/Apple Music etc. 

\
_[Sonarr (tvshows), Radarr (movies) Bazarr (subtitles), Jackett (torrentproxy)](https://wiki.servarr.com/Docker_Guide)_
>A visual, user-friendly tool allowing you to search & add your favourite TV shows (Sonarr) or Movies (Radarr) and subtitles (Bazarr), see a schedule of when the next episodes will air and completely take care of obtaining the requires files (by searching magnets/torrents via Jackett, a proxy for all torrentsites) and organising them, all in order to get a full-blown Nextflix experience served by JellyFin.| For years I have messed with FlexGet, but it can't beat Sonarr.   
>[BLACK app for Android](https://play.google.com/store/apps/details?id=com.advice.drone): Recommended wife/kids friendly app to add series/movies, discover new, enable/disable automatic monitoring of episodes per show and monitor QBittorrent downloads: 

\
_[Qbittorrent](https://hotio.dev/containers/qbittorrent/)_
_[PIA Wireguard VPN](https://hub.docker.com/r/thrnz/docker-wireguard-pia)_ 
>Sonarr, Radarr, Jackett (automatically) add stuff to Qbittorent which is a p2p client. It should run behind the chosen VPN provider.Many alternatives. Transmission is lightweight and originally has a bit better integration with the tools mentioned + allows for port change via the VPN provider.\
>Via the `docker-wireguard-pia` image created by `thrnz`, your downloads are obscured while still allowing you to reach high speeds via the open port in the VPN tunnel, and you can even automatically change the port in Transmission when PIA assigns a new open port, which happens every 90 days.

