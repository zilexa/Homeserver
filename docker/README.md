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
- [Step 1: Tailor the Compose file](https://github.com/zilexa/Homeserver/tree/master/docker#step-2---prepare-verify-and-repeat-your-compose-file-and-repeat)
- [Step 2: Run Docker Compose](https://github.com/zilexa/Homeserver/tree/master/docker#step-3----run-docker-compose)
- [Common docker management tasks](https://github.com/zilexa/Homeserver/blob/master/docker/README.md#common-docker-management-tasks)

Notice the script has placed 2 files in $HOME/docker: `docker-compose.yml` and (hidden) `.env`. 
Notice this folder and its contents are read-only, you need elevated root rights to edit the files. 
Modify docker-compose.yml to your needs and understand the (mostly unique for your setup) variables that are expected in your.env file.   

***

### Step 1 Customisation of Compose file
1. Decide which services you want to run and remove others from this file. Note at the bottom you should remove the corresponding networks as well. 
2. docker-compose.yml: Change the subdomains (for example: `files.$DOMAIN`) to your liking. Also see next step about $CAPS, these are variables for personalisation.
3. docker-compose.yml: Make sure the volume mappings are correct for those that link to the Users or TV folders. Also see next step about variables. 
4. if you remove certain applications, at the bottom also remove unneccary networks.
5. notice the commands at the top of the compose file, for your convenience. 
6. For now, comment out containers that you expose via subdomain until after you have finished [Network Configuration](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md)

### Step 2 Personalisation through variables
_Personalisation_ is done through the .env file. Every variable in the docker-compose.yml is listed here. \
1. Every service in the compose file that you are planning to use, must have its variable filled in the .env file!


***

### Step 3 -  Run Docker Compose
Make sure you commented out or removed services that are exposed via a $DOMAIN name or services that need access to you datapool, unless you completed [Step 2: Filesystem Configuration]() and [Step 3: Network Configuration](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md). 

1. `cd docker` (when you open terminal, you should already be in $HOME).
2. First, Check for errors:  \
```docker-compose -f docker-compose.yml config```
  - `-f` is used to point to the location of your config file. 
  - Notice all variables will automatically be filled. Fix the errors/missing items in the compose or env file. 
3. Run the file. This will download app impages and configure all containers **NEVER prefix with sudo**:  \
```docker-compose -f docker-compose.yml up -d```
  - Anytime you change your docker-compose, simply re-run this command. For example if you change a path to your mediafiles or want to change a domain or port number. 
  - If there was a misconfiguration with an app, for example, a password, simply remove that container (through Portainer, see below) and re-run docker compose command. 

_Notes_
> - All images will be downloaded, containers will be build and everything will start running. 
> - Run again in case you ran into time-outs, this can happen, as a server hosting the image might be temp down. Just delete the containers, images and volumes in Portainer and re-run the command. 
> - **WARNING: if you accidentally prefix with sudo, everything will be created in the root dir instead of the $HOME/docker dir, the container-specific persistent volumes will be there as well and you will run into permission issues. Plus none of the app-specific preperations done by the script will have affect as they are done in $HOME/docker/. Also the specific docker subvolume is not used and not backupped. And you are providing your Docker apps with full admin access to your OS!**
> - To correct this, stop and remove all containers and images via Portainer and remove the /root/docker folder, 

#### Go to portainer: http://localhost:9000 (your.server.lan.ip:9000) login and go to containers. Everything should be green or yellow (temporary). Access any service by clicking its the port number.  

***

## Common Docker management tasks
**Check status of your apps/containers** \
A. Open Portainer (your.server.lan.IP:9000), click containers, green = OK.  \
B. Open a container to investigate, click "Inspect" and make sure "dead=false". Go back, click Log to check logfile.  \
C. If needed, you can even access the terminal of the container and check files/logs directly. But an easier way is to go to those files in $HOME/docker/yourcontainer. Only persistent volumes (mapped via docker-compose.yml) are there. Expendable data (containers, volumes, images) is in/var/lib/docker/.  

**Update individual containers**  \
To update an application, open that container in Portainer, hit `recreate` and check `pull new image`.  \
It is not recommended to use tools like Watchtower to auto-update apps (auto-update is a bad practice in general!). Only the media/download related apps can be consired to auto-update (once a month) since they require frequent updates to keep functioning, this will be done via Pullio. Note the Maintenance guide has solutions for auto-updating docker images. 

**Cleanup docker**  \
To remove unused containers (be careful, this means any stopped container) and dangling images, non-persistent volumes: 
 `sudo docker system prune --all --volumes --force`
Note this will be done automatically via the scheduled maintenance (next guide). 
 
**Update apps**  \
In Portainer, click on a container, then select _Recreate_ and check the box to re-download the image. 
- The latest image will be downloaded and a new container will be created with it. 
- It will still use your persistent volume mappings: your configuration and persistent data remains. Just like a normal application update. 
Note: Monitorr can be used to be notified of updates + update automatically (by default don't do that for all services).  

**Issues:**  \
Permission issues can be solved with the chown and chmod commands.
For example Filerun needs you to own the very root of the user folder (/mnt/pool/Users), not root. 
