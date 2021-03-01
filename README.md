# The Modern Homeserver 
### Setup a lightweight home server usable as desktop workstation or headless, with carefully selected apps to make your life easier and give you the benefits of the "private cloud"! 

This guide uses a declarative methodology, not only to describe and run containerized applications (via docker-compose), but also to install and configure the server and all necessary tools via bash scripts. 

See [Justification](https://github.com/zilexa/Homeserver/blob/master/Justification.md) on the What & the Why and definitely don't start buying stuff before reading [Hardware Recommendations](https://github.com/zilexa/Homeserver/blob/master/Hardware%20recommendations.md). Most information online for pc building and NAS devices do not consider long term stability with fault tolerant components and definitely do not focus on low power consumption. My server uses just 4 WATT, less than a phone charger, comparable to a Raspberry Pi, much less than a Synology yet way more powerful and futureproof. 

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
  - The minimum set of services will be exposed, other containers, applications or services like SSH will only be accessible via VPN:
  - port 80 and 443 for remote HTTPS access, 51822 for VPN access, 22000 for syncing devices.
2. Acquiring your own domain (mydomain.com) for easy and secure (TLS) HTTPS access. This is a requirement for this guide, get it via GoDaddy.com or Porkbun.com.

&nbsp;

## Steps to get up and running: 
### Step 0. Get the files
- Download this repository to your Downloads folder: Click the green "Code" button top left > Download as Zip. 
- Open a Terminal (CTRL+ALT+T) or hit the Budgie start button and start typing "Terminal" or "Tilix. 

NOTES:
  - Opening a script or textfile in Terminal (instead of a normal UI text editor like Pluma) can sometimes prevent you from messing up the file: `nano /path/to/file.sh` note in some cases you need elevated (root) privileges, to do that, prefix a command with `sudo`. 
  - **My system user account is called `asterix`, I use variables as much as possible, but that is not always possible. Make sure you replace "asterix" with your systems username (and read Folder Structure! Because "asterix" is very important in my folder structure).**


### Step 1. Filesystem
[Prepare the filesystem](https://github.com/zilexa/Homeserver/tree/master/filesystem). Install fs tools, understand their goal, tailor to your needs.

### Step 2. Folder Structure
[Create your folder structure](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure). Note my folder structure is simple.  

### Step 3. Prepare server and docker
Install server essential tools and apply basic configuration + apply required stuff for specific docker services:
If you haven't downloaded the file, use this command to do so: `wget https://github.com/zilexa/Homeserver/blob/master/prepare_server_docker.sh`
execute it: `bash prepare_server_docker.sh`
Before you do, please open the file in your text editor (Pluma) first!
The script has clear comments: remove the parts you don't need. For example, if you are not going to use FileRun, that section can be removed. If you ever will use it, make sure to execute those commands first. 

### Step 5. Docker-Compose configuration
See the subguide for [Docker Compose](https://github.com/zilexa/Homeserver/tree/master/docker). **this is the unique part of this guide, a complete and carefully built working Docker-Compose.yml file with variables.**

### Step 6. Configure your Docker applications/services
See the subguide for [Docker Compose](https://github.com/zilexa/Homeserver/tree/master/docker). 

### Step 7. Maintenance
Nightly [maintenance](https://github.com/zilexa/Homeserver/tree/master/maintenance) of your server such as cleanup,  backup and disks protection tasks. 

### Step 8. Local network shares
[Setup NFS](https://github.com/zilexa/Homeserver/tree/master/network%20share%20(NFSv4.2)) a zero-overhead solution used in datacenters, the fastest way to share files/folders with other devices (laptops/PCs) via your local home network.

### Step 9. Configure remote VPN access
[VPN client configs](https://docs.pivpn.io/wireguard/) for yourself and others you trust to access non-exposed services, to manage your server remotely and to use your own adblocker remotely.

&nbsp;

&nbsp;

## Overview of applications and services

Almost everything will run isolated in Docker containers. The setup is easy with the provided docker-compose.yml file, which is a declarative way to pull the images from the internet, create containers and configure everything with a single command! See the [subguide for Docker Compose](https://github.com/zilexa/Homeserver/tree/master/docker) on how to get up and running, **this is the unique part of this guide, a complete and carefully built working Docker-Compose.yml file with variables.** and the correct, well-maintained docker images have been selected, sometimes you spend hours finding the right one as there are often multiple available. 

You can easily find other applications via https://hub.docker.com/
Below a description of each application that are in Docker-Compose.yml. Choose the ones you need.
The only exceptions -apps that run natively on the OS for specific reasons- are Netdata, PiVPN and AdGuard Home. These apps have very easy installation instructions. 

### _Server Management & Monitoring_
_[Netdata](https://learn.netdata.cloud/docs/overview/what-is-netdata)_ - via [Native Install](https://learn.netdata.cloud/docs/agent/packaging/installer)
>Monitoring of system resources, temperature, storage, memory as well as per-docker container resource info. 
>There are other more bloated alternatives (Prometheus+Grafana) that is overkill in a homeserver situation. Netdata requires lm-sensors. 
>Runs natively just because it is such a deeply integrated to get sensor access etc. If you run it in Docker, you might have to fix that access yourself.

_[Portainer](https://www.portainer.io/products/community-edition)_ - via Docker
>a Docker webUI to manage and update containers. Basically a ui of the Docker command. 

_[Organizr](https://github.com/causefx/Organizr)_ - via Docker
>A a customisable homepage to have quick access to all your services/applications. 

_[Dozzle](https://dozzle.dev/)_ - via Docker
>WebUI to check your logs. 

### _User Privacy & Network Security_

_[Traefik](https://doc.traefik.io/traefik/)_ - via Docker
>reverse-proxy for HTTPS access to the services that you want to expose online. Takes care of certification renewal etc. Pretty complicated. Spend lots of time figuring it out. I want to replace Traefik for Caddy soon. 

_[PiVPN](https://www.pivpn.io/)_ - via [Native Install](https://docs.pivpn.io/install/)
>Using the Wireguard VPN protocol, easy and secure access to non-exposed services and to your server (via SSH).
>I highly recommend to use it for DNS & homeserver access by default. All other traffic can bypass the server unless you are connected to unsafe networks (public networks or countries that do not respect privacy). 
>Runs natively because Wireguard-VPN is part of the Linux kernel already. 

_[AdGuardHome](https://adguard.com/en/adguard-home/overview.html)_ - via [Native Install](https://github.com/AdguardTeam/AdGuardHome#getting-started) with _[Unbound](https://github.com/MatthewVance/unbound-docker)_ - via Docker
>Unbound is a recursive DNS resolver. By using Unbound, not 1 ISP and DNS company will know the full URLs of the sites you are visiting. 
>AdGuardHome is a DNS based malware & ad filter. No more ads, malware, coinmining, phishing. All devices on your homenetwork are ad-free and protected, after filtering, the approved DNS requests are forwarded to Unbound, which chops it up in pieces and contacts the end-point DNS providers to get the necessary IP for you to visit the site. This way, not 1 company in the world has your complete DNS requests. With the popular encrypted DNS options (DoH), your request is decrypted at the provider and all end-point DNS providers see your un-encrypted request.
>Can also be used remotely via split tunnel VPN. This means you have 1 adfiltering and DNS resolver for all devices, anywhere in the world (this requires the first DNS server, AdGuardHome, to be outside of Docker). 
>AdGuard Home runs natively otherwise you cannot use it as DNS server when you are remote away from home. 

_[UniFi Controller](https://github.com/goofball222/unifi)_ - via Docker
>Ubiquiti UniFi wireless access points are the best. Recommended for good WiFi in your home. If you don't use their access points you do not need this. If you do have their APs, this is only needed to setup once. 

### _Cloud Experience_

_[FileRun](https://filerun.com/)_ and/or _[NextCloud](https://nextcloud.com/)_ - via Docker
>FileRun is a very fast, lightweight and feature-rich selfhosted alternative to Dropbox/GoogleDrive/OneDrive. It always shows the realtime state of your filesystem. 
>It is not open-source and the free version allows 10 users only. I use it for myself and direct family/friends only. It has no other features: purely a "drive". It does support WebDAV. 
>NextCloud is similar, very popular and free. Not as fast as FileRun but no user-limits. It also has much more features such as Calendar, Contacts etc. I plan to use it to give others ("External Users" in my folder structure) an account on my cloud and as WebDAV music player for my ripped AudioCDs. 

_[OnlyOffice DocumentServer](https://www.onlyoffice.com/office-suite.aspx?from=default)_ - via Docker
>Your own selfhosted Google Docs/Office365 alternative! This works well with both FileRun and NextCloud. 

_[Syncthing](https://syncthing.net/)_ - via Docker
>To sync your devices to your server, Syncthing is the fastest and most lightweight solution for 2-way syncing. FileRun and NextCloud can also do syncing via WebDAV, but I find webDAV not ideal/reliable for syncing everything you want on your phone (photos, app backups etc). On Android, the Syncthing-fork application allows you to easily add your Whatsapp, Signal and other apps backups and photos, camera etc to sync. Always or when charging/when on wifi. iOS does not allow file access, use FileRun/NextCloud.  

_[Firefox Sync](https://github.com/mozilla-services/syncserver)_ - via Docker
>By running your own Firefox Sync server, all your history, bookmarks, cookies, logins of Firefox on all your devices (phones, tablets, laptops) can be synced with your own server instead of Mozilla. Compare this to Google Chrome syncing to your Google Account or Safari syncing to iCloud. It also means you have a backup of your browser profile. This tool has been provided by Mozilla. This is the only browser that allows you to use your own server to sync your browser account!

_[Paperless](https://github.com/jonaswinkler/paperless-ng)_ - via Docker
>Scan files and auto-organise for your administration archive with a webUI to see and manage them. [Background](https://blog.kilian.io/paperless/) of Paperless. No more paper archives!

### _Media Server_

_[Jellyfin](https://jellyfin.org/)_ - via Docker
>A mediaserver to serve clients (Web, Android, iOS, iPadOS, Tizen, LG WebOS, Windows) your tvshows, movies and music in a slick and easy to use interface just like the famous streaming giants do. Jellyfin is userfriendly and has easy features that you might miss from the streaming giants such as watched status management etc. 
The mediaserver can transcode media on the fly to your clients, adjusting for available bandwith. It can use hardware encoding capabilities of your server.

_[Sonarr (tvshows), Radarr (movies) Bazarr (subtitles), Jackett (torrentproxy)](https://wiki.servarr.com/Docker_Guide)_ - via Docker
>A visual, user-friendly tool allowing you to search & add your favourite TV shows (Sonarr) or Movies (Radarr) and subtitles (Bazarr), see a schedule of when the next episodes will air and completely take care of obtaining the requires files (by searching magnets/torrents via Jackett, a proxy for all torrentsites) and organising them, all in order to get a full-blown Nextflix experience served by JellyFin.| For years I have messed with FlexGet, but it can't beat Sonarr.   

_[Transmission](https://hub.docker.com/r/linuxserver/transmission/)_ + [PIA Wireguard VPN](https://hub.docker.com/r/thrnz/docker-wireguard-pia)_  - via Docker
>Sonarr, Radarr, Jackett (automatically) add stuff to Transmission which is a p2p client. It should run behind the chosen VPN provider.Many alternatives. Transmission is lightweight and originally has a bit better integration with the tools mentioned + allows for port change via the VPN provider.  
>Via the `docker-wireguard-pia` image created by `thrnz`, your downloads are obscured while still allowing you to reach high speeds via the open port in the VPN tunnel, and you can even automatically change the port in Transmission when PIA assigns a new open port, which happens every 90 days.

