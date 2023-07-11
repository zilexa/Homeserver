# Step 4: Network configuration

* [Access your services via your own public domain](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md#access-your-services-via-your-own-domain)
* [Access your services via VPN](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md#access-all-other-services-via-wireguard-vpn)
* [Access services in your local network](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md#access-services-in-your-local-network)
* [E-mail notifications](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md#email-notifications)

***

### Access your services via your own domain: 
For most people, exposing only the following services via a domain is enough: 
- FileRun (file cloud)
- VaultWarden (password manager and secure vault)
- Firefox Sync (bookmarks, web history, logins and syncing all of that between devices)  

Understand that you should only expose services online via a domain if it is absolutely necessary. 

_Requirements_

1. Enable dynamic DNS (dyndns) in your router and make a note of the URL. This URL points to your home IP address, even when your ISP changes it.
    * If your router does not have this functionality, use [a free dyndns](https://freedns.afraid.org/) service.
2. Purchase your own domain via a domain provider. I recommend Porkbun (no affiliation).
3. Create subdomains via your domain provider portal for each service/application you want to expose, make sure they reflect the subdomains in your docker-compose.yml file!
4. Configure the DNS settings with your domain provider:
    * an **ALIAS** dns record to your dyndns (`ALIAS - mydomain.com - mydyndnsurl`).
    * an **ALIAS** dns record from www to your domain (`ALIAS - www.mydomain.com - mydomain.com`).
    * a **CNAME** dns record for _each_ subdomain, to your domain, the subdomains should reflect the ones you have in your docker-compose.yml (`CNAME - subdomain.domain.com - mydomain.com`).
5. Configure port forwarding in your router: TCP ports 443 and 80. After you are up and running, you only need port 443 (with Porkbun).
6. If your router supports it, configure a pretty domain that will forward to your local IP, so that you can easily access local services in your LAN without typing IP address.
    * This can also be configured in Adguard Home, even if you do not use its DHCP feature!

 ***

### Access all other services via Wireguard VPN
Consider if you really need direct access to SSH, RDP but also download tools and Jellyfin. You can access all of them safely via VPN when you are not at home and you really need access. To be able to use Wireguard VPN: 

1. Configure port forwarding in your router, Wireguard VPN needs a UDP port, for example 51820. 
2. Finish [Step 5. Docker Compose Guide](https://github.com/zilexa/Homeserver#step-5---docker-compose-guide---customisation-and-personalisation) making sure the containers and  are up and running. 
3. Finish [Step 6. Services & Apps Configuration](https://github.com/zilexa/Homeserver#step-6---configure-your-apps--services) for [Adguard Home](https://github.com/zilexa/Homeserver/blob/master/Applications-Overview.md#safe-browsing-ad--and-malware-free-via-adguardhome---documentation) and [VPN-portal](https://github.com/zilexa/Homeserver/blob/master/Applications-Overview.md#vpn-portal-via-wireguard-ui---documentation).

***

### Access services in your local network
Instead of typing 192.168.0.2:9000 for each service you want to access, configure an easy to remember, local domain address.
This address will work within your home network AND when connected to VPN while outside of your home network: 
1. Go to _AdGuard Home (serverip:3000 or https://localhost:3000) > Settings > DNS rewrite_ 
2. Add a new rule, fill in a domain name for example `myserver.o` and the local IP of your server. 
3. go to http://myserver.o:9000, Portainer should open. Also, AdGuard Home is now accessible via http://myserver.o:3000. 
4. For further instructions how to access specific services without having to type port numbers, see [Step 6. Services & Apps Configuration](https://github.com/zilexa/Homeserver#step-6---configure-your-apps--services), specifically the instructions for [Caddy](https://github.com/zilexa/Homeserver/blob/master/Applications-Overview.md#secure-web-proxy-via-caddy-docker-proxy---documentation) and [Adguard Home](https://github.com/zilexa/Homeserver/blob/master/Applications-Overview.md#safe-browsing-ad--and-malware-free-via-adguardhome---documentation).

***

### Email notifications
Imagine you need to reset your file cloud password, you need a confirmation if someone downloaded a file that you shared or you want confirmation that your nightly backups ran successfully. 
Setting up your own selfhosted SMTP server is a nightmare, because your domain is easily blocked by Gmail, Outlook.com etc. The solution is to use an SMTP service.
* In Porkbun or your domain provider, add an Email Forwarder, *from* `yourname@yourdomain.tld` *to* `yourprivate@email.com`. 
* Create a free account with https://smtp2go.com 
* Login to smtp2go, go to Settings, add an SMTP user for your server to sent notifications and for each docker service that you want to receive notifications from ("send from" accounts). 
  * Make sure the SMTP user name & address correspond with each other. 
    * For example, if want emails to appear to have come from `Jimmies`, and your registered domain is ` jimmies.cloud` create an SMTP user `jimmies`. 
    * If you want emails to appear to have come from FileRun, use `filerun.jimmies`, so that you can use `"FileRun <filerun@jimmies.cloud>"` as sender when configuring your services. 
    * Microsoft refuses to implement common anti-spam protocols for Exchange and outlook.com, as a result some emails can still end up in junk folder, but once marked as non-junk, without having to whitelist, it should be OK. 

