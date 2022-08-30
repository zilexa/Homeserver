This section contains applications I do not use, but did spend lots of time figuring out how to run them properly and make them run as fast/efficient as possible, with minimal containers. 

**NextCloud**\
Nextcloud has 2 versions: Apache/Nginx (default) and Nextcloud-FPM. FPM is the fastest version of Nextcloud. Benefits of my Compose: 
- Isolated network
- Nextcloud PHP-FPM
- Coupled with Redis (caching) for faster/more responsive web UI
- PostgreSQL (fastest database, faster then MariaDB)
- Caddy fully automated https reverse-proxy: much easier to understand and zero other config required
- No Nginx necessary: Caddy is also used as webserver! (Unique!!)

**Grafana with Prometheus**\
In my opinion, overkill for home use: it allows server monitoring with enterprise-grade dashboarding software. \
I use Netdata (outside Docker) which works very good. It has no user-friendly option to personalise the dashboard/create dashboards.\
Note this still contains my old Traefikv2 labels, I highly recommend using Caddy instead as it is a much more simplified setup. 

**PiHole**\
After using PiHole and comparing with AdGuard Home, in my opinion AGH is the better option. It is also open-source and is just a single binary whereas PiHole is a mix of other tools.\
Also: with PiHole in Docker, I could not use it as my DNS server remotely, when connected via VPN.\
With AdGuard Home, when I leave the house, I can stay connected to my own AdGuard Home DNS server, filtering ads etc, while all other traffic bypasses the VPN (no speed drop/barely extra battery consumption). 
