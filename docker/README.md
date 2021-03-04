If you have an understanding of Docker containerization and docker-compose to set it up, realise the following: 
_Containers, Images and non-persistent Volumes are mostly expendable: you can delete them all (basically delete contents of /var/lib/docker), run docker-compose and it will pull all images online, create containers and use your persistent volumes ($HOME/docker/...): the applications should be in the same state as they were before deletion (unless you didn't make the required volumes persistent via compose)._ This makes Docker the most simple, easy and fast way to deploy applications and maintain them. 
Updating = pull new image, re-create container. Usually 1 command or 2 mouse-clicks. 

### Step 1 - Prepare your docker-compose.yml and personalise via environment variables
1. Modify docker-compose.yml and .env to your needs and run docker-compose.  
2. Configure each docker application to your needs. 
3. Open the .env file in a text editor, understand these variables appear in docker-compose.yml. Make sure you fill them in to your needs. Each one needs to be filled in!
4. Open docker-compose.yml and add/remove what you need. Make sure the paths of each volume is correct. 
5. Check for errors: `docker-compose -f docker-compose.yml config` or if you are not in that folder (`cd docker`): docker-compose -f $HOME/docker/docker-compose.yml config

Before running docker-compose, make sure: 
- all app-specific requirements are taken care of. 
- the .env file is complete and correct.
- the docker-compose.yml file is correct. 
- Open a terminal (CTRL+ALT+T or Budgie>Tilix). **Do not prefix with sudo**. `docker-compose -f $HOME/docker/docker-compose.yml up -d`
- If you do prefix with sudo, everything will be created in the root dir instead of the $HOME/docker dir, the container-specific persistent volumes will be there as well and you will run into permission issues. Plus none of the app-specific preperations done by the script will have affect as they are done in $HOME/docker/. Also the specific docker subvolume is not used and not backupped.

All images will be downloaded, containers will be build and everything will start running. 
Run again in case you ran into time-outs, this can happen, as a server hosting the image might be temp down. Just delete the containers, images and volumes in Portainer and re-run the command. 

### Step 2 - Check everything is up and running
5. Go to portainer: yourserverip:9000 login and go to containers. Everything should be green. 
6. To update an application in the future, click that container, hit `recreate` and check `pull new image`. 

### Step 3 - Docker Management
Via Portainer, you can easily access each of your app by clicking on the ports. 
Go ahead and configure each of your applications.


##Frequent tasks
### Check status of your apps/containers
Open Portainer (your.server.lan.IP:9000), click containers, green = OK. 
Open a container to investigate, click "Inspect" and make sure "dead=false". Go back, click Log to check logfile. 
If needed, you can even access the terminal of the container and check files/logs directly. But an easier way is to go to those files in $HOME/docker/yourcontainer. Only persistent volumes (mapped via docker-compose.yml) are there. Expendable data (containers, volumes, images) is in/var/lib/docker/.  

### Update apps
In Portainer, click on a container, then select _Recreate_ and check the box to re-download the image. 
The latest image will be downloaded and a new container will be created with it. 
It will still use your persistent volume mappings: your configuration and persistent data remains. Just like a normal application update. 
