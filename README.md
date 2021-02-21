# The Best Homeserver - Lightweight home server based on microservices, usable as desktop workstation or headless, with carefully selected apps running to make your life easier and give you the benefits of the "private cloud"! 

See [Justification](https://github.com/zilexa/Homeserver/blob/master/Justification.md) on the What & the Why and definitely don't start buying stuff before reading [Hardware Recommendations](https://github.com/zilexa/Homeserver/blob/master/Hardware%20recommendations.md). Most information online for pc building and NAS devices do not consider long term stability with fault tolerant components and definitely do not focus on low power consumption. My server uses just 4 WATT, less than a phone charger, comparable to a Raspberry Pi, much less than a Synology yet way more powerful and futureproof. 

Have a look at [the overview of all applications and services](https://github.com/zilexa/Homeserver/blob/master/README.md#homeserverselfhosted-applications-and-services) that you will have up and running smoothly with this guide. 

## Before you start 
- This guide assumes your system runs Ubuntu v20.04 minimum. Should work on Debian based systems with no or little modification.
- I highly recommend my [Ubuntu Budgie Post Install Script](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script). At least walk through it and use what you need. 
- If you don't, make sure you have a good text editor installed such as Pluma (`sudo apt install pluma`). 
- I had zero Linux experience when I started, so you don't need it, as long as you are ready to Google everything, especially some [basic Linux commands](https://www.hostinger.com/tutorials/linux-commands).
- Download this repository to your Downloads folder: Click the green "Code" button top left > Download as Zip. 
- Open a Terminal (CTRL+ALT+T) or hit the Budgie start button and start typing "Terminal" or "Tilix. 
- opening a script or textfile in Terminal can sometimes prevent you from messing up the file: `nano /path/to/file.sh` note in some cases you need elevated (root) privileges, to do that, prefix a command with `sudo`. 

## Not included: 
1. your router port forwarding of (at least) port 80 and 443 and some more for specific services. 
2. Acquiring your own domain (mydomain.com) for easy and secure (TLS) HTTPS access. This is a requirement for this guide. The minimum set of services will be exposed online and only via HTTPS. Other services can be accessed via Wireguard VPN. 

## Tasks to get up and running: 
### Step 1 Filesystem
[Preparet the filesystem](https://github.com/zilexa/Homeserver/tree/master/filesystem). Install fs tools, understand their goal, tailor to your needs.

### Step 2. Folder Structure
[Create your folder structure](https://github.com/zilexa/Homeserver/tree/master/filesystem#Folder-Structure). Note my folder structure is simple.  

### Step 3. Prepare server and docker
Install server essential tools and apply basic configuration + apply required stuff for specific docker services:
If you haven't downloaded the file, use this command to do so: `wget https://github.com/zilexa/Homeserver/blob/master/prepare_server_docker.sh`
execute it: `bash prepare_server_docker.sh`
Before you do, please open the file in your text editor (Pluma) first!
The script has clear comments: remove the parts you don't need. For example, if you are not going to use FileRun, that section can be removed. If you ever will use it, make sure to execute those commands first. 

### Step 5. Docker-Compose configuration
Modify docker-compose.yml and .env to your needs and run docker-compose.  
Configure each docker application to your needs. 
Open the .env file in a text editor, understand these variables appear in docker-compose.yml. Make sure you fill them in to your needs. Each one needs to be filled in!
Open docker-compose.yml and add/remove what you need. Make sure the paths of each volume is correct. 
Check for errors: `docker-compose -f docker-compose.yml config` or if you are not in that folder (`cd docker`): docker-compose -f $HOME/docker/docker-compose.yml config

Before running docker-compose, make sure: 
1. all app-specific requirements are taken care of. 
2. the .env file is complete and correct.
3. the docker-compose.yml file is correct. 
4. Open a terminal (CTRL+ALT+T or Budgie>Tilix). Do not prefix with sudo. `docker-compose -f $HOME/docker/docker-compose.yml up -d`

All images will be downloaded, containers will be build and everything will start running. 
Run again in case you ran into time-outs, this can happen, as a server hosting the image might be temp down. Just delete the containers, images and volumes in Portainer and re-run the command. 

5. Go to portainer: yourserverip:9000 login and go to containers. Everything should be green. 
6. To update an application in the future, click that container, hit `recreate` and check `pull new image`. 

### Step 6. Configure your Docker applications/services
Via Portainer, you can easily access each of your app by clicking on the ports. 
Go ahead and configure each of your applications. 

### Step 7. Maintenance
Nightly [maintenance](https://github.com/zilexa/Homeserver/tree/master/maintenance) of your server such as cleanup,  backup and disks protection tasks. 

### Step 8. Local network shares
[Setup NFS](https://github.com/zilexa/Homeserver/tree/master/network%20share%20(NFSv4.2)) a zero-overhead solution used in datacenters, the fastest way to share files/folders with other devices (laptops/PCs) via your local home network.

### Step 9. Configure remote VPN access
[VPN client configs](https://docs.pivpn.io/wireguard/) for yourself and others you trust to access non-exposed services, to manage your server remotely and to use your own adblocker remotely.


## Overview of applications and services
### _Server Management & Monitoring_

 _Netdata_
 
 via Docker: no but possible, probably more difficult. 
monitoring of system resources, temperature, storage, memory as well as per-docker container resource info. 
There are other more bloated alternatives (Prometheus+Grafana) that is overkill in a homeserver situation. Netdata requires lm-sensors. 

_Portainer_

a Docker webUI to manage and update containers. Basically a ui of the Docker command. 

_Organizr_

A a customisable homepage to have quick access to all your services/applications. 

_Dozzle_

WebUI to check your logs. 

### _User Privacy & Network Security**

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

### _Cloud Experience**

_FileRun and/or NextCloud_

FileRun is a very fast, lightweight and feature-rich selfhosted alternative to Dropbox/GoogleDrive/OneDrive. It always shows the realtime state of your filesystem. 
It is not open-source and the free version allows 10 users only. I use it for myself and direct family/friends only. It has no other features: purely a "drive". It does support WebDAV. 
NextCloud is similar, very popular and free. Not as fast as FileRun but no user-limits. It also has much more features such as Calendar, Contacts etc. I plan to use it to give others ("External Users" in my folder structure) an account on my cloud and as WebDAV music player for my ripped AudioCDs. 

_OnlyOffice_

Your own selfhosted Google Docs/Office365 alternative! This works well with both FileRun and NextCloud. 

_Syncthing_

To sync your devices to your server, Syncthing is the fastest and most lightweight solution for 2-way syncing. FileRun and NextCloud can also do syncing via WebDAV, but I find webDAV not ideal/reliable for syncing everything you want on your phone (photos, app backups etc). On Android, the Syncthing-fork application allows you to easily add your Whatsapp, Signal and other apps backups and photos, camera etc to sync. Always or when charging/when on wifi. iOS does not allow file access, use FileRun/NextCloud.  

_Firefox Sync_

By running your own Firefox Sync server, all your history, bookmarks, cookies, logins of Firefox on all your devices (phones, tablets, laptops) can be synced with your own server instead of Mozilla. Compare this to Google Chrome syncing to your Google Account or Safari syncing to iCloud. It also means you have a backup of your browser profile. This tool has been provided by Mozilla. This is the only browser that allows you to use your own server to sync your browser account!

_Paperless_

This explains it all: [The Paperless Project](https://github.com/the-paperless-project/paperless)

### _Media Server**

_Jellyfin_

A mediaserver to serve clients (Web, Android, iOS, iPadOS, Tizen, LG WebOS, Windows) your tvshows, movies and music in a slick and easy to use interface just like the famous streaming giants do. Jellyfin is userfriendly and has easy features that you might miss from the streaming giants such as watched status management etc. 
The mediaserver can transcode media on the fly to your clients, adjusting for available bandwith. It can use hardware encoding capabilities of your server.

_Sonarr, Radarr, Bazarr, Jackett_ 
See: https://wiki.servarr.com/Docker_Guide
A visual, user-friendly tool allowing you to search & add your favourite TV shows (Sonarr) or Movies (Radarr) and subtitles (Bazarr), see a schedule of when the next episodes will air and completely take care of obtaining the requires files (by searching magnets/torrents via Jackett, a proxy for all torrentsites) and organising them, all in order to get a full-blown Nextflix experience served by JellyFin.| For years I have messed with FlexGet, but it can't beat Sonarr.   

_Transmission + PIA Wireguard VPN_ 

Sonarr, Radarr, Jackett (automatically) add stuff to Transmission which is a p2p client. It should run behind the chosen VPN provider.Many alternatives. Transmission is lightweight and originally has a bit better integration with the tools mentioned + allows for port change via the VPN provider.  
Via the PIA Wireguard VPN docker image, your downloads are obscured while still allowing you to reach high speeds via the open port in the VPN tunnel. 

