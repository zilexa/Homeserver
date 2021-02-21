# Homeserver
Lightweight home server based on microservices, usable as desktop workstation

See Justification on the What & the Why and definitely don't start buying stuff before reading Hardware Recommendations. Most information online for pc building and NAS devices do not consider long term stability with fault tolerant components and definitely do not focus on low power consumption. My server uses just 4 WATT, less than a phone charger, comparable to a Raspberry Pi, much less than a Synology yet way more powerful and futureproof. 

## Before you start 
- This guide assumes your system runs Ubuntu v20.04 minimum. Should work on Debian based systems with no or little modification.
- I highly recommend my [Ubuntu Budgie Post Install Script](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script). At least walk through it and use what you need. 
- If you don't, make sure you have a good text editor installed such as Pluma (`sudo apt install pluma`). 
- I had zero Linux experience when I started, so you don't need it, as long as you are ready to Google everything, especially some [basic Linux commands](https://www.hostinger.com/tutorials/linux-commands).
- Download this repository to your Downloads folder: Click the green "Code" button top left > Download as Zip. 
- Open a Terminal (CTRL+ALT+T) or hit the Budgie start button and start typing "Terminal" or "Tilix. 
- opening a script or textfile in Terminal can sometimes prevent you from messing up the file: `nano /path/to/file.sh` note in some cases you need elevated (root) privileges, to do that, prefix a command with `sudo`. 

## Not included: 
1. your router port forwarding of (at least) port 80 and 443 and some more for specific services. 
2. Acquiring your own domain (mydomain.com) for easy and secure (TLS) HTTPS access. This is a requirement for this guide. The minimum set of services will be exposed online and only via HTTPS. Other services can be accessed via Wireguard VPN. 

## Tasks to get up and running: 
### Step 1 Filesystem
[Preparet the filesystem](https://github.com/zilexa/Homeserver/tree/master/filesystem). Install fs tools, understand their goal, tailor to your needs.

### Step 2. Folder Structure
[Create your folder structure](https://github.com/zilexa/Homeserver/tree/master/filesystem#Folder-Structure). Note my folder structure is simple.  

## Step 3. Prepare server and docker
Install server essential tools and apply basic configuration + apply required stuff for specific docker services:
If you haven't downloaded the file, use this command to do so: `wget https://github.com/zilexa/Homeserver/blob/master/prepare_server_docker.sh`
execute it: `bash prepare_server_docker.sh`
Before you do, please open the file in your text editor (Pluma) first!
The script has clear comments: remove the parts you don't need. For example, if you are not going to use FileRun, that section can be removed. If you ever will use it, make sure to execute those commands first. 

## Step 5. Docker-Compose configuration
Modify docker-compose.yml and .env to your needs and run docker-compose.  
Configure each docker application to your needs. 
Open the .env file in a text editor, understand these variables appear in docker-compose.yml. Make sure you fill them in to your needs. Each one needs to be filled in!
Open docker-compose.yml and add/remove what you need. Make sure the paths of each volume is correct. 
Check for errors: `docker-compose -f docker-compose.yml config` or if you are not in that folder (`cd docker`): docker-compose -f $HOME/docker/docker-compose.yml config

Before running docker-compose, make sure: 
1. all app-specific requirements are taken care of. 
2. the .env file is complete and correct.
3. the docker-compose.yml file is correct. 
4. Open a terminal (CTRL+ALT+T or Budgie>Tilix). Do not prefix with sudo. `docker-compose -f $HOME/docker/docker-compose.yml up -d`

All images will be downloaded, containers will be build and everything will start running. 
Run again in case you ran into time-outs, this can happen, as a server hosting the image might be temp down. Just delete the containers, images and volumes in Portainer and re-run the command. 

5. Go to portainer: yourserverip:9000 login and go to containers. Everything should be green. 
6. To update an application in the future, click that container, hit `recreate` and check `pull new image`. 

## Step 6. Configure your Docker applications/services
Via Portainer, you can easily access each of your app by clicking on the ports. 
Go ahead and configure each of your applications. 

## Step 7. Maintenance
Nightly [maintenance](https://github.com/zilexa/Homeserver/tree/master/maintenance) of your server such as cleanup,  backup and disks protection tasks. 

## Step 8. Local network shares
[Setup NFS](https://github.com/zilexa/Homeserver/tree/master/network%20share%20(NFSv4.2)) a zero-overhead solution used in datacenters, the fastest way to share files/folders with other devices (laptops/PCs) via your local home network.

## Step 9. Configure remote VPN access
9. [VPN client configs](https://docs.pivpn.io/wireguard/) for yourself and others you trust to access non-exposed services, to manage your server remotely and to use your own adblocker remotely.

### Homeserver/selfhosted applications and services

