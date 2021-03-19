The overview of docker applications included in the compose yml:
https://github.com/zilexa/Homeserver/blob/master/README.md#overview-of-applications-and-services

If you have an understanding of Docker containerization and docker-compose to set it up, realise the following:\
_Containers, Images and non-persistent Volumes are mostly expendable:\
You can delete them all (basically delete contents of /var/lib/docker), run docker-compose and it will pull all images online, create containers and use your persistent volumes ($HOME/docker/...): the applications should be in the same state as they were before deletion (unless you didn't make the required volumes persistent via compose)._ This makes Docker the most simple, easy and fast way to deploy applications and maintain them.\
Updating = pull new image, re-create container. Usually 1 command or 2 mouse-clicks. 

### Step 1 - Prepare your docker-compose.yml and personalise via environment variables
Modify docker-compose.yml to your needs and understand the (mostly unique for your setup) variables that are expected in your.env file.   
Things you need to take care of:
- get your own domain, required for secure https connections for your web applications.
- link your domain to your IP via a dynamic DNS server, modern routers usually have this option.
- set the env variables in the .env file, generate the required secret tokens with the given command.
- in the compose file, make sure the volume mappings are correct.
- if you remove certain applications, also remove the network that it belongs to, unless other apps use it.
- notice the commands at the top of the compose file, for your convenience.
 
### When you are ready
Check for errors: `docker-compose -f docker-compose.yml config` or if you are not in that folder (`cd docker`): docker-compose -f $HOME/docker/docker-compose.yml config

Before running docker-compose, make sure: 
- all app-specific requirements are taken care of. 
- the .env file is complete and correct.
- the docker-compose.yml file is correct. 
- Open a terminal (CTRL+ALT+T or Budgie>Tilix). **Do not prefix with sudo**. `docker-compose -f $HOME/docker/docker-compose.yml up -d`
- **Warning: if you do prefix with sudo, everything will be created in the root dir instead of the $HOME/docker dir, the container-specific persistent volumes will be there as well and you will run into permission issues. Plus none of the app-specific preperations done by the script will have affect as they are done in $HOME/docker/. Also the specific docker subvolume is not used and not backupped.**

All images will be downloaded, containers will be build and everything will start running. 
Run again in case you ran into time-outs, this can happen, as a server hosting the image might be temp down. Just delete the containers, images and volumes in Portainer and re-run the command. 

### Step 2 - Check everything is up and running
5. Go to portainer: yourserverip:9000 login and go to containers. Everything should be green. 
6. To update an application in the future, click that container, hit `recreate` and check `pull new image`. 

### Step 3 - Docker Management
Via Portainer, you can easily access each of your app by clicking on the ports. 
Go ahead and configure each of your applications.


## Frequent tasks
### Check status of your apps/containers
A. Open Portainer (your.server.lan.IP:9000), click containers, green = OK.\
B. Open a container to investigate, click "Inspect" and make sure "dead=false". Go back, click Log to check logfile.\
C. If needed, you can even access the terminal of the container and check files/logs directly. But an easier way is to go to those files in $HOME/docker/yourcontainer. Only persistent volumes (mapped via docker-compose.yml) are there. Expendable data (containers, volumes, images) is in/var/lib/docker/.  

### Update apps
In Portainer, click on a container, then select _Recreate_ and check the box to re-download the image. 
The latest image will be downloaded and a new container will be created with it. 
It will still use your persistent volume mappings: your configuration and persistent data remains. Just like a normal application update. 

Issues:
Permission issues can be solved with the chown and chmod commands.
