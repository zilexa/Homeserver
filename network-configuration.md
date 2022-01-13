# Network configuration

* Access cloud services
* Access services via VPN
* E-mail notifications

***

### Requirements for accessing your selfhosted services online: 
To be able to access your cloud services from anywhere, you need: 
1. Enable dynamic DNS (dyndns) in your router and make a note of the URL. This URL points to your home IP address, even when your ISP changes it. 
  * If your router does not have this functionality, use [a free dyndns](https://freedns.afraid.org/) service. 
2. Purchase your own domain via a domain provider. I recommend Porkbun (no affiliation).  
3. Create subdomains via your domain provider portal for each service/application you want to expose, make sure they reflect the subdomains in your docker-compose.yml file!
4. Configure the DNS settings with your domain provider: 
  * an **ALIAS** dns record to your dyndns (`ALIAS - mydomain.com - mydyndnsurl`). 
  * an **ALIAS** dns record from www to your domain (`ALIAS - www.mydomain.com - mydomain.com`).
  * a **CNAME** dns record for _each_ subdomain, to your domain, the subdomains should reflect the ones you have in your docker-compose.yml (`CNAME - subdomain.domain.com - mydomain.com`).
5 Configure port forwarding in your router: TCP ports 443 and 80. After you are up and running, you only need port 443 (with Porkbun). 
6 If your router supports it, configure a pretty domain that will forward to your local IP, so that you can easily access local services in your LAN without typing IP address. 
  * This can also be configured in Adguard Home, even if you do not use its DHCP feature!
 
 ***
 
### Requirement to access your non-exposed services online
It is highly recommended to expose the absolute minimum set of services via a domain. Consider if you really need direct access to SSH, RDP but also download tools and Jellyfin. 
You can access all of them safely via VPN when you are not at home and you really need access. 
To be able to use Wireguard VPN: 
* Configure port forwarding in your router, Wireguard VPN needs a UDP port, for example 51820. 
* Install Wireguard on your devices that need access (note Linux has it built in). 
  * Example: Smartphones in my household auto-connect to VPN when I leave the house. Only my server domain address goes through VPN. This way, ads are always filtered even when I am not at home and I can always access all services.

***

### Requirement for email notifications from services and server
Imagine you need to reset your file cloud password, you need a confirmation if someone downloaded a file that you shared or you want confirmation that your nightly backups ran successfully. 
Setting up your own selfhosted SMTP server is a nightmare, because your domain is easily blocked by Gmail, Outlook.com etc. The solution is to use an SMTP service.
* Create a free account with https://smtp2go.com 
* configure "send from" addresses for each service/subdomain and one for your server. 

