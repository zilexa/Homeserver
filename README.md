# The Modern Homeserver 
### Setup a lightweight home server usable as desktop workstation or headless, with carefully selected apps to make your life easier and give you the benefits of the "private cloud"! 

This guide uses a declarative methodology, not only to describe and run containerized applications (via docker-compose), but also to install and configure the server and all necessary tools via bash scripts. See [What is a Container?](https://www.docker.com/resources/what-container) to get a quick understanding why Docker is now the default way to deploy, run and manage web applications and how it differs from virtual machines.  

See [Justification](https://github.com/zilexa/Homeserver/blob/master/Justification.md) on the What & the Why and definitely don't start buying stuff before reading [Hardware Recommendations](https://github.com/zilexa/Homeserver/blob/master/Hardware%20recommendations.md). Most information available online for pc building and NAS devices do not consider **long term stability** and low power consumption with **fault tolerant components**: they focus on downloading stuff and just storing them. **My server uses just 4 WATT**, less than a phone charger, comparable to a Raspberry Pi, much less than a Synology (a popular ready-to-use NAS system) yet way **more powerful and futureproof**. 

Have a look at [the overview of all applications and services](https://github.com/zilexa/Homeserver/blob/master/README.md#overview-of-applications-and-services) that you will have up and running smoothly with this guide. 

Note: I had zero experience when I started and learned everything by googling, spending time on fora, reddit and in documentations and by hours and days of trial&error. I made lots of mistakes. Now, in case of disaster I will use the scripts in this repository myself to get up and running again. I am documenting this because I haven't found a single source online that provides _all necessary information_ to get up and running. Also, lot's of things have been carefully chosen after testing alternatives. You can save lots of time with this guide! :) 


## Before you start 
- The OS used is Ubuntu Budgie, because it is one of the most light-weight and extremely user-friendly of all Linux options. As this script is for beginners, it will help to have an intuitive OS to set everything up. Ofcourse, you can run the server headless (without UI, even without a monitor) . 
- **Please follow the [OS Installation Guide.](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script/blob/master/OS-installation/README.md) Step 3 (BtrFS filesystem) is required for this guide!**
- **In addition, run my post-install script [Ubuntu Budgie Post Install Script](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script). It's meant for home desktops and laptops but it also takes care of some OS essentials and generally recommended (by experts) btrfs subvolumes. At least use the parts of the script that make sense, especially the subvolumes.**
- Make sure you have a good text editor installed such as Pluma (`sudo apt install pluma`), this is done by the post-install script. 
- I had zero Linux experience when I started, so you don't need it, as long as you are ready to Google everything, especially some [basic Linux commands](https://www.hostinger.com/tutorials/linux-commands).

## Not included: 
1. Your router port forwarding:
    - The minimum set of services should be exposed via portforwarding to your server IP: **TCP ports 80 and 443** for remote HTTPS access, **UDP port 51820** for Wireguard-VPN access via PiVPN, **TCP and UDP port 22000** for syncing devices via Syncthing.
    - other containers, applications or services including SSH will only be accessible via VPN.
2. Acquiring your own domain (mydomain.com) for easy and secure (TLS) HTTPS access. This is a requirement for this guide, get it via GoDaddy.com or Porkbun.com.

&nbsp;

## Steps to get up and running: 
### Step zero. Get the files
- Download this repository to your Downloads folder: Click the green "Code" button top left > Download as Zip. 
- Open a Terminal (CTRL+ALT+T) or hit the Budgie start button and start typing "Terminal" or "Tilix. 

NOTES:
  - Opening a script or textfile in Terminal (instead of a normal UI text editor like Pluma) can sometimes prevent you from messing up the file: `nano /path/to/file.sh` note in some cases you need elevated (root) privileges, to do that, prefix a command with `sudo`. 
  - **My system user account is called `asterix`, I use variables instead of personal names, but that is not always possible. Make sure you replace "asterix" with your systems username (and read Folder Structure! Because "asterix" is also very important in my folder structure).**


### Step 1. Filesystem
[Prepare the filesystem](https://github.com/zilexa/Homeserver/tree/master/filesystem). Install fs tools, understand their goal, tailor to your needs.

### Step 2. Folder Structure
[Create your folder structure](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure). Note my folder structure is simple.  

### Step 3. Prepare server and docker
Continue to [Docker & server setup](https://github.com/zilexa/Homeserver/tree/master/docker) and use the bash script to automatically or manually install essential tools, apply basic configuration + required stuff for specific docker services. Get up and running in minutes via Docker Compose: _**this is the unique part of this guide, a complete and carefully built working Docker-Compose.yml file with variables.**_

### Step 4. Maintenance
Nightly [maintenance](https://github.com/zilexa/Homeserver/tree/master/maintenance) of your server such as cleanup,  backup and disks protection tasks. 

### Step 5. Local network shares
[Setup NFS](https://github.com/zilexa/Homeserver/tree/master/network%20share%20(NFSv4.2)) a zero-overhead solution used in datacenters, the fastest way to share files/folders with other devices (laptops/PCs) via your local home network.

### Step 6. Configure remote VPN access
[VPN client configs](https://docs.pivpn.io/wireguard/) for yourself and others you trust to access non-exposed services, to manage your server remotely and to use your own adblocker remotely.

&nbsp;


## Overview of applications and services

Almost everything will run isolated in [Docker containers](https://www.docker.com/resources/what-container). The setup is easy with the provided docker-compose.yml file, which is a declarative way to pull the images from the internet, create containers and configure everything with a single command! See the [subguide for Docker Compose](https://github.com/zilexa/Homeserver/tree/master/docker) on how to get up and running, **this is the unique part of this guide, a complete and carefully built working Docker-Compose.yml file with variables.** and the correct, well-maintained docker images have been selected, sometimes you spend hours finding the right one as there are often multiple available. 

You can easily find other applications via https://hub.docker.com/
Below a description of each application that are in Docker-Compose.yml. Choose the ones you need.
The only exceptions -apps that run natively on the OS for specific reasons- are Netdata, PiVPN and AdGuard Home. These apps have very easy installation instructions. 

### _Server Management & Monitoring_
_[Netdata](https://learn.netdata.cloud/docs/overview/what-is-netdata)_ - via [Native Install](https://learn.netdata.cloud/docs/agent/packaging/installer)
>Monitoring of system resources, temperature, storage, memory as well as per-docker container resource info. 
>There are other more bloated alternatives (Prometheus+Grafana) that is overkill in a homeserver situation. Netdata requires lm-sensors. 
>Runs natively just because it is such a deeply integrated to get sensor access etc. If you run it in Docker, you might have to fix that access yourself.

_[Portainer](https://www.portainer.io/products/community-edition)_ - via Docker
>An complete overview of your containers and related elements in a nice visual UI, allowing you to easily check the status, inspect issues, stop, restart, update or remove containers that you launched via Docker Compose. Strangely, the tool cannot inform you of updates.  

_[Organizr](https://github.com/causefx/Organizr)_ - via Docker
>A a customisable homepage to have quick access to all your services/applications. 

### _User Privacy & Network Security_

_[Caddy](https://caddyserver.com/)_ - via [docker caddy proxy](https://github.com/lucaslorentz/caddy-docker-proxy)
>reverse-proxy for HTTPS access to the services that you want to expose online. Takes care of certification renewal etc. Caddy already extremely simplifies the whole https process to allow browsers and apps A+ secure connection to your server. Docker Caddy Proxy goes one step further and allows you to set it up per container with just 2 lines! Alternatives like Traefik are needlessly complicated.   

_[PiVPN](https://www.pivpn.io/)_ - via [Native Install](https://docs.pivpn.io/install/)\
Mobile Apps: [WireGuard](https://play.google.com/store/apps/details?id=com.wireguard.android) + [Automate](https://play.google.com/store/apps/details?id=com.llamalab.automate)
>Using the Wireguard VPN protocol, easy and secure access to your non-exposed applications (including SSH & SFTP) on your server.
>Allows you to always use your own DNS (AdGuard Home + Unbound), giving you the same ad-free, secure internet access while outside of your home network, while still allowing direct regular internet access (bypasses the tunnel, only DNS + server IP access goes via the tunnel). Optionally, when in a less secure public environment, let all traffic on your mobile go via the tunnel.  

_[AdGuardHome](https://adguard.com/en/adguard-home/overview.html)_ - via Docker with _[Unbound](https://github.com/MatthewVance/unbound-docker)_ - via Docker
>Unbound is a recursive DNS resolver. By using Unbound, not 1 ISP and DNS company will know the full URLs of the sites you are visiting. 
>AdGuardHome is a DNS based malware & ad filter. No more ads, malware, coinmining, phishing. All devices on your homenetwork are ad-free and protected, after filtering, the approved DNS requests are forwarded to Unbound, which chops it up in pieces and contacts the end-point DNS providers to get the necessary IP for you to visit the site. This way, not 1 company in the world has your complete DNS requests. With the popular encrypted DNS options (DoH), your request is decrypted at the provider and all end-point DNS providers see your un-encrypted request.
>Can also be used remotely via split tunnel VPN. This means you have 1 adfiltering and DNS resolver for all devices, anywhere in the world (this requires the first DNS server, AdGuardHome, to be outside of Docker). 
>AdGuard Home runs natively otherwise you cannot use it as DNS server when you are remote away from home. 

_[UniFi Controller](https://github.com/goofball222/unifi)_ - via Docker\
Mobile App: [Unifi Network](https://play.google.com/store/apps/details?id=com.ubnt.easyunifi)
>Ubiquiti UniFi wireless access points are the best. Recommended for good WiFi in your home. If you don't use their access points you do not need this. If you do have their APs, this is only needed to setup once. 

### _Cloud Experience_

_[Bitwarden](https://github.com/dani-garcia/bitwarden_rs)_ - via Docker\
Mobile App: [Bitwarden](https://play.google.com/store/apps/details?id=com.x8bit.bitwarden)
> Easily the best, user friendly password manager out there. Open source and therefore fully audited to be secure. The mobile apps are extremely easy to use. By using `bitwarden_rs`, written in the modern language RUST, it users exponentially less resources than the conventional Bitwarden-server. 

_[FileRun](https://filerun.com/)_ instead of NextCloud - via Docker\
Mobile Apps: [CX File Explorer](https://play.google.com/store/apps/details?id=com.cxinventor.file.explorer) and [FolderSync](https://play.google.com/store/apps/details?id=dk.tacit.android.foldersync.lite) (for phone backup).
>FileRun is a very fast, lightweight and feature-rich selfhosted alternative to Dropbox/GoogleDrive/OneDrive. Nextcloud, being much slower and overloaded with additional apps, can't compete on speed and user-friendliness. Also, with FileRun each user has a dedicated folder on your server and unlike Nextcloud, FileRun does not need to periodically scan your filesystem for changes. 

>It is not open-source and the free version allows 10 users only. I use it for myself and direct family/friends only. It has no calendar/contacts/calls etc features like Nextcloud. It does support WebDAV, ElasticSeach for in-file search, extremely fast scrolling through large photo albums, encryption, guest users, shortened sharing links etc. 

> Although FileRun documentation recommends the Nextcloud mobile app, it is quite a useless and unfriendly app. CX File Explorer (4.8 stars) is a swift and friendly Android file manager that allows you to add your FileRun instance via WebDAV. It also allows SFTP access. 

> FolderSync is THE app for Android when you run your own filecloud, allowing you to sync the data of your apps (photos, chat apps, backup of your 2FA app (Aegis), home screen settings etc.) to your server, instead of to Google Drive. It also allows local sync: moving all app-specific backup files (like whatsapp\databases) to a single backup dir first before syncing it to your server. 

_[OnlyOffice DocumentServer](https://www.onlyoffice.com/office-suite.aspx?from=default)_ - via Docker
>Your own selfhosted Google Docs/Office365 alternative! This works well with both FileRun and NextCloud. 

_[Syncthing](https://syncthing.net/)_ - via Docker
>Syncthing is the fastest and most lightweight solution for 2-way syncing, allowing you to sync user files on your laptop or other users PC/laptops/NAS to your server.  FileRun (like Nextcloud) can also do syncing via WebDAV, but is more suitable to regularly backup your mobile devices to your server instead of constantly keeping an exact copy of your GB's of data on a PC or laptop. 

_[Firefox Sync](https://github.com/mozilla-services/syncserver)_ - via Docker
>By running your own Firefox Sync server, all your history, bookmarks, cookies, logins of Firefox on all your devices (phones, tablets, laptops) can be synced with your own server instead of Mozilla. Compare this to Google Chrome syncing to your Google Account or Safari syncing to iCloud. It also means you have a backup of your browser profile. This tool has been provided by Mozilla. This is the only browser that allows you to use your own server to sync your browser account!

_[Paperless](https://github.com/jonaswinkler/paperless-ng)_ - via Docker
>Scan files and auto-organise for your administration archive with a webUI to see and manage them. [Background](https://blog.kilian.io/paperless/) of Paperless. No more paper archives!

### _Media Server_

_[Jellyfin](https://jellyfin.org/)_ - via Docker\
Mobile & TV Apps: [Jellyfin clients](https://jellyfin.org/clients/) (for series/movies), [Gelli](https://github.com/dkanada/gelli/releases) (amazing Music Player)
>A mediaserver to serve clients (Web, Android, iOS, iPadOS, Tizen, LG WebOS, Windows) your tvshows, movies and music in a slick and easy to use interface just like the famous streaming giants do. Jellyfin is userfriendly and has easy features that you might miss from the streaming giants such as watched status management etc. 
The mediaserver can transcode media on the fly to your clients, adjusting for available bandwith. It can use hardware encoding capabilities of your server.

_[Sonarr (tvshows), Radarr (movies) Bazarr (subtitles), Jackett (torrentproxy)](https://wiki.servarr.com/Docker_Guide)_ - via Docker
>A visual, user-friendly tool allowing you to search & add your favourite TV shows (Sonarr) or Movies (Radarr) and subtitles (Bazarr), see a schedule of when the next episodes will air and completely take care of obtaining the requires files (by searching magnets/torrents via Jackett, a proxy for all torrentsites) and organising them, all in order to get a full-blown Nextflix experience served by JellyFin.| For years I have messed with FlexGet, but it can't beat Sonarr.   

_[Transmission](https://hub.docker.com/r/linuxserver/transmission/)_ + [PIA Wireguard VPN](https://hub.docker.com/r/thrnz/docker-wireguard-pia)_  - via Docker\
Mobile App: [Transmission Remote](https://play.google.com/store/apps/details?id=net.yupol.transmissionremote.app)
>Sonarr, Radarr, Jackett (automatically) add stuff to Transmission which is a p2p client. It should run behind the chosen VPN provider.Many alternatives. Transmission is lightweight and originally has a bit better integration with the tools mentioned + allows for port change via the VPN provider.  
>Via the `docker-wireguard-pia` image created by `thrnz`, your downloads are obscured while still allowing you to reach high speeds via the open port in the VPN tunnel, and you can even automatically change the port in Transmission when PIA assigns a new open port, which happens every 90 days.

