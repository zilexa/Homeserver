New job, no time to write a guide, I will need a week or 2. 
The below will be a lot shorter/summarised, there will be an overall step-by-step guide and a more detailed guides per item (post-OS install preparation, docker preparation and additional guides per function like VPN, DNS config etc). 

# A quiet, efficient future-proof and scalable home-server. 


Go directly to the Installation Guide: https://github.com/zilexa/Homeserver/setup/README.md

### [What is it? And Why?](https://github.com/zilexa/Homeserver#what-is-it)
### [Why self-build?](https://github.com/zilexa/Homeserver#why-self-build-just-buy-a-synology-or-qnap)
### [What are the benefits of your setup files?](https://github.com/zilexa/Homeserver#what-are-the-benefits-of-adopting-your-setup-and-config-fully-or-partially)
### [How does the installation work?](https://github.com/zilexa/Homeserver#how-does-the-installation-work)
### [Can I use the server as PC or workstation?](https://github.com/zilexa/Homeserver#can-i-use-the-server-as-pc-or-workstation-but-i-have-never-used-ubuntu)
### [What Services are included?](https://github.com/zilexa/Homeserver#what-services-will-it-provide)

## What is it?

An always-on PC like device that you can place near your router or even use as your Desktop/workstation. Giving you access to your data, providing you with a higher level of privacy and security and allowing you to be flexible with all online services you might use. 

Why?
1. Be in control of your own precious data, think archived family photos and videos but also new photos from your next vacation. 
2. No paid subscriptions to Dropbox/Google Drive/Onedrive. 
3. No vendor lock-in: mostly open source based software gives you freedom to choose whatever platform you like (Android/iOS/Windows/Ubuntu/Web). 
4. No vendor lock-out: moving from iOS to Android? Figuring out how to get your data migrated can be a hassle. 
5. Because it is really cool, energy efficient and you can support your family, extended family with your server, so that they don't run in to the limitations that paid cloud solutions come with. 

## Why self-build? Just buy a Synology or QNAP..?
4 reasons: 
1. A self-build (hardware) server can be 5 times more power efficient. Imagine this system will be powered on 24/7/365. A Synology or QNAP can easily consume 8-15W in idle, while a self-build server can achieve idle power consumption of less than 5W (some even less than 3W). That is probably less than most of your electronic devices *on standby*. 
2. It will allow you to install any service you might need and is very future-proof as you can add services easily in the future, without vendor lock-in. 
3. A self-build homeserver is simply much faster, as it will contain a much faster CPU and more/faster RAM and modern SSD to run the applications. 
4. Scalability & upgrades: you can easily add a cheap SSD as cache or add HDDs if you need more space. 

## What are the benefits of adopting your setup and config (fully or partially)?

 - A LOT OF CARE has gone into sane selections of the right tool, finding the best configuration,  
 - To allow everything to run fast, smooth, efficient and still be scalable. 
 - Sometimes things have been optimised to squeeze out maximum speed, even though it is not necessary (might be if you add lots of users). 
 - I have been a perfectionist and spent lots of time researching many tools, discussing with developers on fora, Discord, Reddit to figure out what would allow me to run my rock-stable server with as little as maintenance as possible.  
 - The tools listed here are only a small subset of the tools I have investigated as I sometimes spent a whole day researching alternatives.
 - Other guides only provide part of the equation. With my scripts, you can litteraly start from scratch. 

## How does the installation work?
 The scripts will take care of preparing an Ubuntu (or Debian) based machine, installing and configuring necessities for the system and prepare the per-service requirements. 
Folder structure is important, the first script requires you to think about it as it will install the harddrive pooling software and mount drives optimised for data (fast compression filesystem), SSD (medium  compression filesystem) or backup (high compression file system), which means you need to determine how which drives/many drives you will use for data. 
Changing things later on is possible but might require careful moving of data (and reboot of your system, which causes the services to go offline for everyone).
When done, what is left is to configure services that I cannot easily configure via a script or that simply need to be personalised. 

## Can I use the server as PC or workstation? But I have never used Ubuntu..
You can, I do. Switched cold-turkey from Windows. You can find a [post-installation automated script for Ubuntu](https://github.com/zilexa/UbuntuBudgie-config) here. That is how I configure PCs for parents and friends, after running the script they are good to go, it even adds Macbook-like touchpad gestures. It also installs carefully selected common tools, such as Photoflare, which is in my opinion the Linux alternative to Paint and Paint.net (GIMP is not that user-friendly).  
All applications that run on Windows or Mac run on Ubuntu with only a couple of exceptions, for which great open-source alternatives exist. Note you can even install MS Office 2019 or 365 since Wine 6.0 has been released. My server is fast enough to run 22 services in the background, while I am culling my photo collection. It's only a Core i3-9100. 

## What Services will it provide?

There are 4 categories of services, the first category is essential, but you might not need all of its services. 
1) **Server Management & Monitoring**

2) **Privacy and Network Security**

3) **File Cloud Experience**

4) **TV media** ;)

### Note: 
Each service can have one or more dependencies on tools that are only discussed in the installation guide. 
For example:
- Netdata requires lm-sensors, which is a tool everyone should install anyway to read-out system sensors. 
- Filerun uses ElasticSearch allowing you to not only search your files, but also search within your files, extremely fast. It also uses AESCrypt to allow file encryption and OnlyOffice can be installed to allow server-side document editing (Google Docs alternative). 

**Category 1: Server Management & Monitoring**
|Service| Description  | Rationale 
|-|--|--|
|**Netdata** | Monitor and visualise temperature and resource usage per service and for the entire system.  (how much free space is left? Is a service taxing my CPU unnessarily? etc)| I have tried other, like Prometheus and Grafana, which allow you to build your own dashboards. But that goes beyond the goal of the homeserver. You won't be constantly looking at monitoring dashboards. Netdata is therefore sufficient: less flexible to create own dashboards, but the default dashboard is complete and readable. 
|**Portainer**| manage, update and access Docker services| It is the default choice for Docker users. 
|**Organizr**| The portal to your home-server! A responsive web app that gives you access to all your services and allows services to show current status on the homepage. Especially nice for category 4.| The only one that is actively developed and works well. The alternative: ... was too minimalistic in my opinion. |


**Category 2: User Privacy & Network Security**
|Service| Description  | Rationale 
|-|--|--|
|**Traefik, SSL proxy**| Some of your services need to be accessible outside your home network. Traefik gives HTTPS access to these services, which is required by modern browsers these days. It allows 2-way encrypted connection with all exposed services. It is a one-time-setup and never look at it again service, taking care of SSL renewals etc| Nginx is an alternive, Traefik is more modern, easier to configure and has a nice web interface.  
|**PiVPN, VPN server**| Access your services when you are on the road. Services should only be exposed on the internet via Traefik if it is absolutely necessary. Otherwise, you use VPN to connect with your server| PiVPN is by far the easiest solution to get a Wireguard VPN server up and running in seconds. With Wireguard, you have a stateless connection and the most efficient VPN protocol to date. When not at home, you can have a constant VPN connection via your phone, even use your own DNS server though the VPN tunnel when on the road or travelling through countries that block common websites and don't respect privacy.  
|**AdGuardHome, ad-aware DNS server**| AdGuardHome (set as default DNS server in your router) is an open-source (not to be confused with closed source AdGuard) ad-aware DNS server: all requests are filtered, filtering out malware domains, hijacked sites, advertising and tracking requests. This will easily block 10% of all your internet requests! Browsing will be a lot faster| PiHole is more popular and well-known. After using it for a few months, AdGuardHome became a clear alternative: it's a single binary application with 1 config file, which means you can run it bare-metal (outside of Docker) and benefit from it easily when on the road (the road-warrior setup does not work with PiHole in combination with macvlan). PiHole consists of multiple 3rd party tools connected via PHP. Since there are lots of new developments in DNS (like QUIC protocol), Pihole is a bit limited to support these on the short term.   
|**Unbound, recursive DNS server**| Instead of sending every URL you visit to your ISP or favourite DNS provider (Google, Cloudflare), who will sent it to several DNS organisations you have no clue about (that is how internet works) you can keep your browsing private with your own recursive DNS server. besides that Unbound allows for extra security protocols and methods to protect you| Unbound is a unique project, Google it to learn more. With Unbound, not 1 party will ever receive the full URL you are trying to receive. Contrary to DNS-over-HTTPS, where only the connection to the first DNS server is encrypted. 
|**UniFi Controller**| Optional: if you have UniFi WiFi in your house, a controller adds features and optimises the connections.| UniFi has pretty good WiFi equipment smoothly integrate within your house interior. |


**Category 3: Cloud Experience**
|Service| Description  | Rationale 
|-|--|--|
|**FileRun (and/or NextCloud)**| alternative to you your file cloud (dropbox/onedrive/googledrive. Much faster interface (FileRun) and speed only limited by your ISP. Uses several other features to provide speed and to allow text searches within files (ElasticSearch) | FileRun is the fastest free solution, with an incredibly user-friendly interface that provides many features. Con: limited to 10 users. Use it for yourself and your family. Nextcloud can be used as alternative offer to external users or the users that will barely use it anyway.  
|**OnlyOffice DocumentServer**| integrated with FileRun and Nextcloud: allowing you to view, edit and create documents on any device, without them ever leaving the server |OnlyOffice is not trying to be the best at providing OpenDocument support. Instead it supports MS Office documents and has a similar interface. It works very fast, is secure and there are not much alternatives. 
|**Syncthing + hardlinked backups**| automatically sync your phone photos, password manager database, favourite chat app backup, launcher app settings to your server as backup (one-way) and restore them to a new phone simply by enabling 2-way sync on your phone.  |Syncthing is abased 2-way sync solution. It is unmatched in speed. Although FileRun and Nextcloud offer syncing (webDAV), Syncthing is much better for stable syncing and large/lots of files. Together with a tool that backups synced data automatically, it is a must-have for every homeserver. If you have multiple devices online (laptop, homeserver, backup server at your parents), you can profit from the principles of p2p by uploading/downloading to/from multiple destinations/sources. |
|**Firefox Sync Server**| Sync your browser profile | If you use Chrome or Firefox and you have multiple devices, you can have the same bookmarks, history, logins, open tabs etc across devices (or just have a backup online in case your device goes missing or breaks). With Firefox Sync Server, you no longer sync with Google or Mozilla but simply with your own server. This tool has been provided by Mozilla for home-server owners. |



**Category 4: TV media**
|Service| Description  | Rationale 
|-|--|--|
|**JellyFin, mediaserver**| Jellyfin Server serves its clients (apps on your devices) with content, providing them with a Netflix-like, user-friendly experience (much better, as Nextflix doesn't even allow you to mark stuff as watched/unwatched or remove from your watchlist)| It can do everything Plex does, but is fully open-source and free software. It is mature enough to replace Plex, although the AndroidTV client still needs some refinement (temporary workaround: install Kodi and the JellyFin add-on). 
|**Sonarr, Radarr, Bazarr, Jackett**| A visual, user-friendly tool allowing you to search & add your favourite TV shows (Sonarr) or Movies (Radarr) and subtitles (Bazarr), see a schedule of when the next episodes will air and completely take care of obtaining the requires files (by searching magnets/torrents via Jackett, a proxy for all torrentsites) and organising them, all in order to get a full-blown Nextflix experience served by JellyFin.| For years I have messed with FlexGet, but it can't beat Sonarr.   
|**Transmission**| Sonarr, Radarr, Jackett (automatically) add stuff to Transmission which is a p2p client. It should run behind the chosen VPN provider.| Many alternatives. Transmission is lightweight and originally has a bit better integration with the tools mentioned + allows for port change via the VPN provider.  
|**VPN client**| While PiVPN installs a VPN-server on your server to access it from outside of your network, this is a VPN client to connect to PIA, a VPN service provider to access internet via its servers. It allows you to run any application via its network. Transmission will only have internet access via this service.| A carefully chosen provider and docker image: it allows, automatic server selection, Wireguard connection (greatly improves p2p speed) and allows port communication with Transmission. |

this should be deleted:
Correct folder structure and Docker setup for torrents:
https://old.reddit.com/r/usenet/wiki/docker#wiki_consistent_and_well_planned_paths
