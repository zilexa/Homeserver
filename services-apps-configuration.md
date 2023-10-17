# Step 6. Services & Apps - Configuration

Your services will run isolated in [Docker containers](https://www.docker.com/resources/what-container). The setup is easy with the provided docker-compose.yml file, which is a declarative way to pull the images from the internet, create containers and configure everything with a single command!

See the [subguide for Docker Compose](https://github.com/zilexa/Homeserver/tree/master/docker) on how to get up and running. *this is the unique part of this guide, a complete and carefully built working Docker-Compose.yml file with variables.*

The best, well-maintained docker images have been selected, sometimes you spend hours finding the right one as there are often multiple available.  

- You can easily find other applications via https://hub.docker.com/
- For VPN through WireGuard, Remote Desktop through RDP and terminal access through SSH, the host OS, Manjaro Gnome, is leveraged. 
- To remove the complexity of configuring Wireguard VPN, a friendly VPN-Portal webservice is included and the most complex part of a VPN server configuration is already taken care of in the docker-compose.yml file!

Below a description and recommended or required configuration of each service that are in Docker-Compose.yml. Choose the ones you need.


## _Server Management & Monitoring_
### _Container management_ via [Portainer](https://www.portainer.io/products/community-edition)
>A complete overview of your containers and related elements in a nice visual UI, allowing you to easily check the status, inspect issues, stop, restart, update or remove containers that you launched via Docker Compose. Strangely, the tool cannot inform you of updates.
- Required configuration: none.
- Recommended configuration: Settings > Environment > Local, Public IP. Change this value to your local domain name, as configured in AdGuard Home>DNS Rewrites or your systems hosts file (`/etc/hosts`), more details below in the AdGuard Home section. 

### _Secure Web Proxy_ via caddy-docker-proxy - [documentation](https://github.com/lucaslorentz/caddy-docker-proxy)
> Access your services via a pretty domain name, accessible via the internet through HTTPS or locally only.  \
> For online access, Caddy takes care of all required steps, obtaining and renewing SSL certificates etc. 100% hassle free!  \
> Caddy-Docker-Proxy is the same as official Caddy but allows you to configure Caddy via Docker Compose file, instead of managing a seperate configuration file (`caddyfile`). Caddy-Docker-Proxy will dynamically built the caddyfile based on labels in your Docker Compose file.

> Only services that absolutely need to be accessed online should be exposed to the internet. These are Vault Warden (Bitwarden password manager), FileRun (file and photo cloud) and Firefox Sync (browser profile and configuration syncing).\
> All other services can still be accessed via a pretty domain, one that is only accessible within your LAN or when connected to your server via VPN. 
- Required configuration: Caddy is near-zero configuration but does require you to do your homework first.
  - _To access services via internet securily:_
    - Complete [Step 3. Network Configuration](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md) of the main guide.
    - personalize the docker-compose file by editing the .env file and setting your own registered domain name and email address.
    - (Optional) personalize the docker-compose file by changing the subdomains (files., vault., firefox.) to your liking, matching the configuration of your domain provider.
  - _To access local services via a pretty domain name:_`
    - (Optional) personalize the docker-compose file, changing the caddy label under each service to a domain name of your liking. For example, to access Portainer, `http://docker.o/` is used, you could also use `http://docker.home/` or something else instead.  
    - Add all the local domain names as they appear in the compose file to AdGuard Home (see below) or to your system `/etc/hosts` file, each one pointing to the same LAN IP address of your server, no port numbers (DNS translates domains to IP addresses, ports are not involved here, Caddy makes sure the right service is connected to each domain). 

### _Safe browsing ad- and malware free_ via AdGuardHome - [documentation](https://adguard.com/en/adguard-home/overview.html)
_Your own recursive DNS server to stop sharing your browsing history with the world_ Unbound - [documentation](https://github.com/MatthewVance/unbound-docker)_ 
>Unbound is a recursive DNS resolver. By using Unbound, no 3rd party will know the full URLs of the sites you are visiting (your ISP, local and international DNS providers).\
>AdGuardHome is a DNS based malware & ad filter, blocking ad requests but also blocking known malware, coinmining and phishing sites!

>After AGH filters the requests, the remaining DNS requests are forwarded to Unbound, which chops it up in pieces and contacts the end-point DNS providers to get the necessary IP for you to visit the site.\
>This way, not 1 company in the world has your complete DNS requests. Compare this to the hyped encrypted DNS (DoH): your request is decrypted at the provider, the provider and all end-point DNS providers see your un-encrypted request.

>By blocking on DNS request level, you easily block 5-15% of internet traffic requests, significantly reducing the data needed to load websites, run apps and play games.\
>All devices connected to your router such as home speakers, smart devices, mediaplayer etc are automatically protected.\
>This setup can also be used used remotely via split tunnel VPN (see PiVPN). This means you have 1 adfiltering and DNS resolver for all devices, anywhere in the world.
- Required configuration: 
  - walkthrough the first time wizard at http://serverip:3000
  - **Settings>General Settings**: Disable "Use Adguard Browsing Security Service", this will sent every request to Adguard. Makes no sense and slows down. 
  - **Settings>DNS Settings**: Upstream DNS servers should only contain your unbound service: `127.0.0.1:5335`
  - **Filters>DNS blocklists**: click "Add blocklist">"Choose from the list" select `OISD Blocklist Full`, hit save, then uncheck others and only check `OISD Blocklist Full`. 
  - **Filters>DNS blocklists**: click "Add blocklist">"Add a custom list", in a new browser tab go to https://gitlab.com/malware-filter/urlhaus-filter#url-based-adguard and find the "URL-based (AdGuard) Lite" list, copy that URL, paste it into Adguard and give it a name `URLHaus malware filter`, save and make sure to select it to be active. You now have 2 of the best filters. If they block too much, switch to OISD Lite instead of Full. 
  - **Filters>DNS Rewrites**: Add DNS rewrites for each local (not online exposed) service you want to access via a local domain instead of having to type ip:port all the time. For example, add `docker.o`, `192.168.88.2` to access Portainer by going to `http://docker.o/`, if your server lan IP is 192.168.88.2, and do the same for example for `vpn.o` to access the Wireguard Portal where you will manage VPN clients, `jellyfin.o` to access you media etc. 
    - Browsers convert addressess automatically to HTTPS. Disable this in your browser security settings. Type a `/` at the end of the address (if that's not enough also add `http://` in front of it) to force it to use http instead. HTTPS TLS encryption is not necessary (and more work to setup for local services) since these domains only work within your LAN (or via VPN which is already encrypted).  
    - For services (like Adguard Home!) using `network_mode: host` in docker-compose, this works only when accessing the domain on other devices within your LAN. To access such services in a browser on your host system, add the domain in the `/etc/hosts` file of your server.

### _VPN Portal_ via wireguard-ui - [documentation](https://github.com/ngoduykhanh/wireguard-ui)
> Wireguard VPN protocol runs natively on your host system, it is part of the Linux Kernel. A configuration file containing the VPN server configuration and encryption keys should be generated and stored in a file `/etc/wireguard/wg0.conf`. Clients can be configured by generating keys and adding them to that file.

> This webservice does 1 thing: it provides a `VPN-Portal`, a friendly user interface to add/manage clients and manage global default settings for server and clients. This means all it does is edit the configuration file.

> Most of its configuration is already taken care of, see the docker-compose file.

> The `server-prep.sh` script will ensure the system monitors the config file for changes and restart the host Wireguard VPN program for changes to immediately become effective.

> Note your server IP when connected via VPN will be `10.0.0.0` and clients will start at `10.0.0.1`. 

_Server configuration_ 
- Personalize docker-compose by editing your (hidden) `/home/username/docker/.env` file [see example](https://github.com/zilexa/Homeserver/blob/master/docker/.env).
  1. Set a user/pw for VPN-Portal access
  2. Generate a key for VPN-Portal access encryption key `WGPORTALSECRET`, see the command listed in the file under section TOKENS.  
  3. your registered domain name `yourdomain.tld` (see [Step 3. Network Configuration](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md)) 
  4. your SMTP provider credentials, required to sent clients a QR code or conf file for access.
  5. verify `WGPORT` is properly forwarded in your router and `LAN_ADDRESS_RANGE` corresponds with your router DHCP range. 
  6. Set the correct LAN network device in `POSTUP` and `POSTDOWN` by changing `eno1` to yours, can be found via command `ip route`, the value next to "dev" on the 'default' or first line. 
  7.  In Terminal, verify no errors have been made: `docker-compose config` and check all values from .env are present. Then run `docker-compose up -d`. 
- Go to the vpn portal via `yourip:5000` or `http://vpn.o/` and verify your `.env` values are filled in. 
- Go to `Clients` and add clients. 
  - `keepalive` should only be used for non-mobile clients, its purpose is access from server >> client (instead of vice versa) by keeping the outgoing (client>>server) connection alive. 
  - Change AllowedIPs to your liking: `10.0.0.0/24` =  access to server and VPN peers, `192...../24` = access to all LAN devices (like printer, camera). If you just want all traffic of the client to go through VPN, also internet traffic: `0.0.0.0, ::/0` (= all IPv4 and IPv6 traffic). If you only want to allow access to 1 IP instead of a whole range use `/32`. Also see this [range calculator](https://www.ipaddressguide.com/cidr). 
    - You can always change `AllowedIPs`, later, on your client itself. If you want to prevent clients from having access to certain IP addresses or server ports, change the POST UP and POST DOWN lines, as this configures the server firewall. For inspiration, see [here](https://gist.github.com/qdm12/4e0e4f9d1a34db9cf63ebb0997827d0d). 
- Do not forget to hit `Apply Config`. This will save the changes to `/etc/wireguard/wg0.conf`. 
- Open a Terminal, verify WireGuard starts correctly (no errors): `sudo wg-quick up wg0`, if there were no errors, stop it again `sudo wg-quick up wg0`. 
- Enable starting it as service (will autostart at boot): `sudo systemctl enable wg-quick@wg0.service` and `sudo systemctl start wg-quick@wg0.service`.
- To automatically apply changes made via VPN-Portal, Wireguard needs to be restarted when the `wg0.conf` file is modified by VPN-Portal. File monitoring and restarting is done via 2 services created by the `prep-server.sh` script. All you have to to is enable & start them: : `systemctl enable wgui.{path,service}` and `systemctl start wgui.{path,service}`. This will run `sudo systemctl restart wg-quick@wg0.service` when the `wg0.conf` file is modified.

_Client configuration_ 
- Wireguard apps are available for all systems. For Linux, install `wireguard-tools` and use the command `wg-quick up wg0` after you have put the client conf file (accessible via the VPN-Portal) in `/etc/wireguard/`. More user-friendly, Linux with Gnome UI support Wireguard out-of-the box via Settings > Network. 
- You can easily ensure Android devices are always using your server DNS (and have access to all local non-exposed services!) by installing [WG-Tunnel](https://play.google.com/store/apps/details?id=com.zaneschepke.wireguardautotunnel), adding the configuration through QR code or file, which you can share via the `VPN-Portal` via email to your devices Portal. [WG-Tunnel](https://github.com/zaneschepke/wgtunnel) is amazing. It uses the same base as the official Wireguard app, but allows you to automatically connect to your VPN (DNS-traffic only) when you leave your home WiFi and disconnect when you are back home! Set up once and forget!
- WG Tunnel also works on AndroidTV, allowing you to share your Nexflix subscription through your VPN server, by simply having them install the app on their AndroidTV. After importing the client config file all they have to do is go into its settings ("edit") and apply the tunnel to "included apps" only, selecting Netflix. Easy!

### _Remote Admin Access_ via RDP and SSH
> You can manage your server remotely, within LAN or, when not at home via VPN. This can be done through the terminal or simply by accessing the desktop, by sharing the desktop through RDP. 
> Manjaro Gnome has Gnome RDP builtin by default and the `post-install.sh` script already installed it and allowed you to set the credentials. 
- Required Configuration: 
  - Go to Settings > Sharing. Enable it at the top and enable `Remote Desktop` (=RDP) and `Remote Login` (= SSH). 
  - If you need to, you can change the Remote Desktop credentials. Only use letters and numbers for password. 
 - Optional: 
   - For terminal access, open a console or terminal and simply use `ssh serverusername@10.0.0.0` which is your server IP when connected through VPN. 
   - On Android, terminal SSH access is easy via the Termius app. File access through FTP-over-SSH (SFTP) is easy via the CX Explorer app, which also has webDAV support (for your FileRun filecloud) and is a great Android Filemanager, very user friendly.     
   - For Remote Desktop via a MacOS, use the Remmina app.   
   - For Remote Desktop via Manjaro Gnome or other Gnome distribution: use Gnome Connections (`post-install.sh` script installs this already). 
 

## _Cloud Services_
### _Password Manager_ via Vaultwarden [documentation](https://github.com/dani-garcia/vaultwarden)
>Mobile App: [Bitwarden](https://play.google.com/store/apps/details?id=com.x8bit.bitwarden)
> Easily the best, user friendly password manager out there. Open source and therefore fully audited to be secure. The mobile apps are extremely easy to use.\
> Additionally allows you to securely share passwords and personal files or documents (IDs, salary slips, insurance) with others via Bitwarden Send.\
> By using `bitwarden_rs`, written in the modern language RUST, it uses exponentially less resources than the conventional Bitwarden-server.
- Required documentation:
  - Follow the documentation to login to the admin environment (hint: the secret in your `.env` file). 
    - User registeration is disabled by default, you can invite users via email.
    - Fill in your SMTP credentials first and perform the test. See [E-mail notifications](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md#email-notifications) in [Step 3. Network Configuration](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md).   

### _Files cloud_ via FileRun - [documentation](https://docs.filerun.com/) and [support](https://feedback.filerun.com)_ 
>Mobile Apps: [CX File Explorer](https://play.google.com/store/apps/details?id=com.cxinventor.file.explorer) (for file browsing) and [FolderSync](https://play.google.com/store/apps/details?id=dk.tacit.android.foldersync.lite) (for 2-way or 1-way sync, automated or scheduled) or Goodreader for iOS.
> - FileRun is a very fast, lightweight and feature-rich selfhosted alternative to Dropbox/GoogleDrive/OneDrive. Nextcloud, being much slower and overloaded with additional apps, can't compete on speed and user-friendliness. Also, with FileRun each user has a dedicated folder on your server and unlike Nextcloud, FileRun does not need to periodically scan your filesystem for changes.
> - FileRun support WebDAV, ElasticSeach for in-file search, extremely fast scrolling through large photo albums, encryption, guest users, shortened sharing links etc.
>Limits compared to Nextcloud: It is not open-source and the free version allows 10 users only. I use it for myself and direct family/friends only. It has no calendar/contacts/calls etc features like Nextcloud.
- Required configuration: 
- walk through the Control Panel and personalize at will. 
- In `Plugins`, enable what you need, disable overlapping stuff that you do not need. In `defaults` it is recommended to use `Office web viewer` for Office documents instead of alternatives.
- In `E-mail` disable "instant notifications" to prevent users from being flooded with hundreds of emails when shared files are being downloaded. See [Maintenance & Scheduling](https://github.com/zilexa/Homeserver/tree/master/maintenance-tasks#step-6-schedule-nightly-and-monthly), cron will be used to sent notifications every 5min. 
- OnlyOffice DocumentServer unfortunately does not work properly, otherwise you could configure OnlyOffice as default to edit office documents (having your own google docs/office online alternative!). 

**How to sync devices, external users laptops**
> - Filerun supports webDAV, see [helpful tips](https://docs.filerun.com/webdav). This way you benefit from instant file indexing (for search) and server-side photo thumbails & previews. Consider using webDAV to sync your User files with your mobile devices.
> - For mobile devices [FolderSync](https://www.tacit.dk/) or Goodreader (iOS) are the apps to use for syncing when you run your own filecloud, since they properly support webDAV.
> - For mobile devices, to surf through your files, [CX File Explorer](https://play.google.com/store/apps/details?id=com.cxinventor.file.explorer) is very user-friendly.
> - For desktops and laptops and to keep your parents PC user files in-sync, consider webDAV as well. For Linux, the NextCloud Desktop client is the obvious choice as it is the only tool that does 2-way sync.
> - The Nextcloud mobile app works with FileRun but CX File Explorer (4.8 stars) is so much better and easier to use. It is a swift and friendly Android file manager that allows you to add your FileRun instance via WebDAV. Compared to the Nextcloud app, it allows you to easily switch between your local storage and your cloud, copying files betweeen them.
> - Alternatively, [Setup NFS](https://github.com/zilexa/Homeserver/tree/master/network%20share%20(NFSv4.2)) a zero-overhead solution used in datacenters, the fastest way to share files/folders with other devices (laptops/PCs) via your local home network.

### _Your own browser sync engine via Firefox Sync - [documentation](https://github.com/mozilla-services/syncserver)_
>By running your own Firefox Sync server, all your history, bookmarks, cookies, logins of Firefox on all your devices (phones, tablets, laptops) can be synced with your own server instead of Mozilla.\
>Compare this to Google Chrome syncing to your Google Account or Safari syncing to iCloud. It also means you have a backup of your browser profile. This tool has been provided by Mozilla. This is the only browser that allows you to use your own server to sync your browser account!
- Required Configuration: 
  - Test your sync server is running properly by visiting the subdomain `firefox.yourdomain.tld`. 
  - by default, new accounts cannot register to your server. You can control this in your docker-compose file via `FF_SYNCSERVER_ALLOW_NEW_USERS:` make sure to set it to false after all users have registered, to prevent strangers from using your sync server. 

### _Remote Desktop Web Client [Guacamole](https://github.com/MaxWaldorf/guacamole)_
>Access any desktop (your server or your parents laptop) through RDP via your browser (mobile browsers supported as well) after connecting to VPN.  \
>Instead of using an app, you can simply go to https://remote.yourdomain.com and use the web application to login to the desktop of any server/desktop/laptop that has RDP configured.  \
>You still need to be connected to your server VPN.  \
>You can connect all computers that you want to support (like, parents) to your server VPN. Then, when they need help, you simply open a browser, login to Guacamole to see and use their desktop.  

- Decide whether you need the web client, since you can just as well use desktop applications (Remmina on Linux, Mac and Android, Windows RDP in Windows 10/11). 
- If you do need it, decide whether or not you want to expose the client to the internet or only access the client through LAN and VPN. Remember, to actually connect to your server you will need to connect to VPN anyway. 
  - Since 18/07/2022 the docker-compose.yml example exposes it by default + enables 2FA for this web app. 
  - If you do not want to expose it, remove the 2 caddy labels (or replace them for local proxy, to access via http://remote.o/ within your LAN/VPN) and remove the `TOTP` in the Extensions section. 

How to Configure Guacamole?
- login with guacadmin/guacadmin. 
- Find Settings in the top-right menu, _Settings > Users > New User_ and create a user for yourself.
- Logout, login with your own user, go back to _Settings > Users_ and delete user guacadmin.
- _Settings > Connections > New Connection:_ Name = your server name, protocol = RDP, Concurrency limits = 1, 
- Section _Parameters > Network_ fill in hostname (= a LAN hostname that you created in AdGuard or LAN IP or VPN IP), Port = 3389. Under _Authentication_ your server RDP username/password. Hit Save. 

## _Media Server_
### _[Qbittorrent](https://hotio.dev/containers/qbittorrent/)_ through VPN-proxy via PIA Wireguard VPN - [documentation](https://hub.docker.com/r/thrnz/docker-wireguard-pia)_ 
>Downloading files should always be done through a proper VPN provider, one that allows for port forwarding otherwise finding peers will be difficult.\
>The `docker-wireguard-pia` image created by `thrnz` automatically connects/reconnects/finds fastest server and even updates the forwarded port in QBittorrent, as your PIA provider will change it often.
- Required configuration: 
  - Open the file `/home/username/docker/VPN-proxy/pia-shared/updateport-qb.sh` and fill in your QBittorrent username & password and the LAN IP of your server. This way, this script can access QBittorrent to automatically update the forwarded port when PIA changes it (happens after every reboot, restart or reconnect). 

\
_Series/Movies/Subtitles/Music via Sonarr/Radarr/Bazarr/Lidarr and torrentsites proxy Prowlarr - [Documentation](https://wiki.servarr.com/Docker_Guide)_
>A visual, user-friendly tool allowing you to search & add your favourite TV shows (Sonarr) or Movies (Radarr) and subtitles (Bazarr), see a schedule of when the next episodes will air and completely take care of obtaining the requires files (by searching magnets/torrents via Jackett, a proxy for all torrentsites) and organising them, all in order to get a full-blown Nextflix experience served by JellyFin.| For years I have messed with FlexGet, but it can't beat Sonarr.   
- [BLACK app for Android](https://play.google.com/store/apps/details?id=com.advice.drone): all-in-1 app allows you to perform most popular actions in your "\*arr" apps.
- [NZB360 app for Android](https://play.google.com/store/apps/details?id=com.kevinforeman.nzb360): all-in-1 app allows you to discover new content, find/add/remove content, view status and manage all your "\*arr" services and downloads in 1 single app. User friendly and completely replaces the need to access your web apps. 

\
_Media server via Jellyfin - [documentation](https://jellyfin.org/)_
>A mediaserver to serve clients (Web, Android, iOS, iPadOS, Tizen, LG WebOS, Windows) your tvshows, movies and music in a slick and easy to use interface just like the famous streaming giants do.\
>Jellyfin is user-friendly and has easy features that you might miss from the streaming giants such as watched status management etc.\
The mediaserver can transcode media on the fly to your clients, adjusting for available bandwith. It can use hardware encoding capabilities of your server.\
> By using the Gelli app, Jellyfin competes with music servers such as SubSonic/AirSonic. Gelli is more slick and in active development.\
> Allows you to listen to your old AudioCDs! A HiRes Audio alternative to Spotify/Apple Music etc. 
