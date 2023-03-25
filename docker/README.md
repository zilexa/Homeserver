# STEP 4: Host Server & Docker Configuration Guide

If you have an understanding of Docker containerization and docker-compose to set it up, realise the following:
- _Containers and Images and **non-persistent** are expendable:_
  - Deletion of a container/image does not delete its config/data.
  - You can remove them completely, move your persistent volumes ($HOME/docker/...) to a different computer/laptop, run docker-compose and be back online in minutes with your own configuration (= your persistent volumes. That is how easy it will be to restore your server or re-create an application when there is an issue!
- _This makes Docker the most simple, easy and fast way to deploy applications and maintain them._
  - Updating = pull new image & re-create container. 
- _**Check the homepage for [the overview of docker applications](https://github.com/zilexa/Homeserver/blob/master/README.md#overview-of-applications-and-services) included in the compose file.**_

***

**Contents**
- [Step 1: Customisation and Personalisation](https://github.com/zilexa/Homeserver/blob/master/docker/README.md#step-1---customisation-and-personalisation-of-compose-file)
- [Step 2: Run Docker Compose](https://github.com/zilexa/Homeserver/blob/master/docker/README.md#step-2----run-docker-compose)
- [Common docker management tasks](https://github.com/zilexa/Homeserver/blob/master/docker/README.md#common-docker-management-tasks)

Notice the script has placed 2 files in $HOME/docker: `docker-compose.yml` and (hidden) `.env`. 
Notice this folder and its contents are read-only, you need elevated root rights to edit the files. 
Modify docker-compose.yml to your needs and understand the (mostly unique for your setup) variables that are expected in your.env file.   

***

### Step 1 - Customisation and Personalisation of Compose file
1. Decide which services you want to run and remove others from this file. Note at the bottom you should remove the corresponding networks as well. 
2. if you remove certain applications, at the bottom also remove unneccary networks.
3. If you have not registered your own domain (see [Network Configuration](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md), comment out services that are exposed through the internet. 
4. If your datapool is not configured/mounted (see [Step 2: Filesystem Configuration](https://github.com/zilexa/Homeserver/tree/master/filesystem)) comment out services that have a mount to the datapool.. 

5. _Personalisation_ is mostly done through the .env file. Go through it and adjust. Every variable in the compose file (like your domain name, the root path of your datapool, mail credentials) is stored here. 
6. docker-compose.yml: Change the subdomains (for example: `files.$DOMAIN`) of exposed services and the local domains (like http://g.o or http://sonarr.o) to your liking.
7. docker-compose.yml: Make sure the volume mappings are correctly reflecting your folder structure, especially for FileRun and the media services like QBittorrent and Sonarr.

***

### Step 2 -  Run Docker Compose
Make sure you commented out or removed services that are exposed via a $DOMAIN name or services that need access to you datapool, unless you completed [Step 2: Filesystem Configuration](https://github.com/zilexa/Homeserver/tree/master/filesystem) and [Step 3: Network Configuration](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md). 

1. `cd docker` (when you open terminal, you should already be in $HOME).
2. First, check for errors:  \
```docker-compose -f docker-compose.yml config```
  - `-f` is used to point to the location of your config file. 
  - Notice all variables will automatically be filled. Fix the errors/missing items in the compose or env file (see Step 2). 
3. If decided to keep caddy-docker-proxy, create the required external network first:  \
```docker network create web-proxy```
4. Now run the file. This will download app impages and configure all containers **NEVER prefix with sudo**:  \
```docker-compose -f docker-compose.yml up -d```
  - Anytime you change your docker-compose, simply re-run this command. For example if you change a path to your mediafiles or want to change a domain or port number. 
  - If there was a misconfiguration with an app, for example, a password, simply remove that container (through Portainer, see below) and re-run docker compose command. 

_Notes_
> - All images will be downloaded, containers will be build and everything will start running. 
> - Run again in case you ran into time-outs, this can happen, as a server hosting the image might be temp down. Just delete the containers, images and volumes in Portainer and re-run the command. 
> - notice the commands at the top of the compose file, for your convenience. 
> - **WARNING: if you accidentally prefix with sudo, everything will be created in the root dir instead of the $HOME/docker dir, the container-specific persistent volumes will be there as well and you will run into permission issues. Plus none of the app-specific preperations done by the script will have affect as they are done in $HOME/docker/. Also the specific docker subvolume is not used and not backupped. And you are providing your Docker apps with full admin access to your OS!**
> - To correct this, stop and remove all containers and images via Portainer and remove the /root/docker folder, 


### Step 3 -  Configure easy access to your services
You can now access each service via its port number, for example, check the status of your containers by going to Portainer: http://SERVERIP:9000/ (your.server.lan.ip:9000).  \
A better solution is to access them via the local domains that you configured through Caddy Labels under each container. For example: http://docker.o to access Portainer.  \
You need to register these domains in AdGuard Home to get them working:. \
- Go to http://SERVERIP:3000 and walkthrough the initial wizard. See here for tips. Then go to Filters > DNS Rewrites and add your local domains one by one, each pointing to your SERVERIP without portnumbers.
- In your home router, replace all DNS addresses (usually under "DHCP"), only your SERVERIP should be listed (there is no such thing as a backup DNS, secondary DNS can be used anytime so remove it).
- Now disable/enable your server network connection, check if you can access websites and refresh AdGuard page. Stats should show some activity.
- Go to `http://go.o/`, this is your server start page! It's simple, shows status of your services and allows you to access them. There are no configuration options, just the labels in your docker-compose.yml file. For a dashboard with lots of features and configuration options, consider [Dashy by Lizzy](https://github.com/Lissy93/dashy). 
***

## Common Docker management tasks
**Check status of your apps/containers** \
A. Open Portainer (your.server.lan.IP:9000), click containers, green = OK.  \
B. Open a container to investigate, click "Inspect" and make sure "dead=false". Go back, click Log to check logfile.  \
C. If needed, you can even access the terminal of the container and check files/logs directly. But an easier way is to go to those files in $HOME/docker/yourcontainer. Only persistent volumes (mapped via docker-compose.yml) are there. Expendable data (containers, volumes, images) is in/var/lib/docker/.  

**Update individual containers**  \
To update an application, open that container in Portainer, hit `recreate` and check `pull new image`.  \
- It is not recommended to auto-update all apps (auto-update is a bad practice in general!). Only the media/download related apps can be considered to auto-update (once a month) since they require frequent updates to keep functioning.
- The Maintenance guide runs Pullio to auto-update images/containers that have the Pullio label in Compose. For other applications, a notification can be emailed when updates are available. 

**Cleanup docker**  \
To remove all unused containers (be careful, this means any stopped container) and all dangling images and all non-persistent volumes: 
 `sudo docker system prune --all --volumes --force`
Note this will be done automatically via the scheduled maintenance (next steps). 
 
**Issues:**  \
Permission issues can be solved with the chown and chmod commands.
For example Filerun needs you to own the very root of the user folder (/mnt/pool/Users), not root. 
