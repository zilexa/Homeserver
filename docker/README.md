# STEP 3: Host Server & Docker Configuration Guide

If you have an understanding of Docker containerization and docker-compose to set it up, realise the following:
- _Containers, Images and non-persistent Volumes are mostly expendable:_
  - You can delete them all (basically delete contents of /var/lib/docker), run docker-compose and it will pull all images online, create containers and use your persistent volumes ($HOME/docker/...): the applications should be in the same state as they were before deletion (unless you didn't make the required volumes persistent via compose).
- _This makes Docker the most simple, easy and fast way to deploy applications and maintain them._
  - Updating = pull new image, re-create container. Usually 1 command or 2 mouse-clicks. Deletion of a container/image does not delete its config/data. 
- _**Check the homepage for [the overview of docker applications](https://github.com/zilexa/Homeserver/blob/master/README.md#overview-of-applications-and-services) included in the compose file.**_

***

**Contents**
- [Step 1: Get Server Essentials](https://github.com/zilexa/Homeserver/tree/master/docker#step-1---get-docker-and-essential-server-tools)
- [Step 2: Tailor the Compose file](https://github.com/zilexa/Homeserver/tree/master/docker#step-2---prepare-verify-and-repeat-your-compose-file-and-repeat)
- [Take a break, configure your network](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md)
- [Step 3: Run Docker Compose](https://github.com/zilexa/Homeserver/tree/master/docker#step-3----run-docker-compose)
- [Common docker management tasks](https://github.com/zilexa/Homeserver/blob/master/docker/README.md#common-docker-management-tasks)

***

### Step 1 - Get Docker and essential server tools
Scan the [PREP_DOCKER.SH](https://github.com/zilexa/Homeserver/blob/master/prep-docker.sh) and see what it does. 

Download and install it via: 
```
cd Downloads && wget https://raw.githubusercontent.com/zilexa/Homeserver/master/prep-docker.sh
bash prepare-docker.sh
```
_Notes_
> - A subvolume for Docker will be created --> allows extremely easy daily or hourly backups and recovery
> - Installs Docker in rootless mode for enhanced security. This reduces the attack serface of your server. 
> - Allows OS support to send emails (with minimal set of tools and configuration), several Docker containers and your maintenance tasks will need this.
> - Installs several other essential tools, essential for example for data migration, backups, maintenance.
> - Optional config files for a few services (will ask y/n before downloading).For example if you are going to use torrents, consider using the QBittorrent config file. Also the Organizr config might be nice and will save you lots of time building your own "Start" page.

***

### Step 2 - Prepare, Verify (and repeat) your Compose file (and repeat)
Notice the script has placed 2 files in $HOME/docker: `docker-compose.yml` and (hidden) `.env`. 
Notice this folder and its contents are read-only, you need elevated root rights to edit the files. 
Modify docker-compose.yml to your needs and understand the (mostly unique for your setup) variables that are expected in your.env file.   

##### 2a Things you need to take care of:
1. .env file: set the env variables in the .env file, generate the required secret tokens with the given command.
2. docker-compose.yml: Change the subdomains (for example: `files.$DOMAIN`) to your liking.
3. docker-compose.yml: Make sure the volume mappings are correct for those that link to the Users or TV folders. 
4. if you remove certain applications, at the bottom also remove unneccary networks.
5. notice the commands at the top of the compose file, for your convenience. 


##### 2b Check for typos or errors
`cd docker` (when you open terminal, you should already be in $HOME).
Check for errors: `docker-compose -f docker-compose.yml config` (-f is used to point to the location of your config file). 

_Notes_ 
> 1. all app-specific requirements are taken care of.
> 2. the .env file is complete and correct.
> 3. the docker-compose.yml file is correct. 
> 4. You have commented out/removed the services that require a domain. Unless you have completed your [Network Configuration](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md).

***

### Step 3 -  Run Docker Compose
Make sure you have finished [Network Configuration](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md).

1. Open a terminal (CTRL+ALT+T or Budgie>Tilix). **NEVER prefix with sudo**. `docker-compose -f $HOME/docker/docker-compose.yml up -d`
2. Anytime you change your docker-compose, simply re-run this command. For example if you change a path to your mediafiles or want to change a domain or port number. 

_Notes_
> - All images will be downloaded, containers will be build and everything will start running. 
> - Run again in case you ran into time-outs, this can happen, as a server hosting the image might be temp down. Just delete the containers, images and volumes in Portainer and re-run the command. 
> - **WARNING: if you accidentally prefix with sudo, everything will be created in the root dir instead of the $HOME/docker dir, the container-specific persistent volumes will be there as well and you will run into permission issues. Plus none of the app-specific preperations done by the script will have affect as they are done in $HOME/docker/. Also the specific docker subvolume is not used and not backupped. And you are providing your Docker apps with full admin access to your OS!**
> - To correct this, stop and remove all containers and images via Portainer and remove the /root/docker folder, 

#### Go to portainer: yourserverip:9000 login and go to containers. Everything should be green or yellow temporary). Access any service by clicking its the port number.  
Make sure you finish [Network Configuration](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md) before running Docker Compose with the services that require a domain. Anytime you change 

***

## Common Docker management tasks
**Docker Management** 
Via Portainer, you can easily access each of your app by clicking on the ports. 
Go ahead and configure each of your applications.
I recommend configuring a dns record in your router OR use AdGuard Home > Settings > DNS rewrite to create easy urls like my.server to access all your services via my.server:portnumber and configure Organizr, so that you can access ALL services within your LAN and via VPN via 1 url. 

**Check status of your apps/containers**
A. Open Portainer (your.server.lan.IP:9000), click containers, green = OK.\
B. Open a container to investigate, click "Inspect" and make sure "dead=false". Go back, click Log to check logfile.\
C. If needed, you can even access the terminal of the container and check files/logs directly. But an easier way is to go to those files in $HOME/docker/yourcontainer. Only persistent volumes (mapped via docker-compose.yml) are there. Expendable data (containers, volumes, images) is in/var/lib/docker/.  

**Update individual containers**
6. To update an application, open that container in Portainer, hit `recreate` and check `pull new image`. It is not recommended to use tools like Watchtower to auto-update apps (auto-update is a bad practice in general!). Only the media/download related apps can be consired to auto-update (once a month) since they require frequent updates to keep functioning. Note the Maintenance guide has solutions for auto-updating docker images or notifying you of updates.

**Cleanup docker**
To remove unused containers (be careful, this means any stopped container) and dangling images, non-persistent volumes: 
 `sudo docker system prune --all --volumes --force`
 Note this will be done automatically via the scheduled maintenance (next guide). 
 
**Update apps**
In Portainer, click on a container, then select _Recreate_ and check the box to re-download the image. 
The latest image will be downloaded and a new container will be created with it. 
It will still use your persistent volume mappings: your configuration and persistent data remains. Just like a normal application update. 
Note: Monitorr can be used to be notified of updates + update automatically (by default don't do that for all services).  

**Issues:** 
Permission issues can be solved with the chown and chmod commands.
For example Filerun needs you to own the very root of the user folder (/mnt/pool/Users), not root. 

_NEXT STEPS..._
Continue with Step 4 or 5 (order does not matter) of the main guide, configuring your [Network](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md) or your [data drives](https://github.com/zilexa/Homeserver/tree/master/filesystem). 
