<h1 align="center"><strong>The Modern HomeServer</strong></h1>
<h3 align="center"><strong>A complete Guide, making it just as simple and easy to setup and maintain your own, fully flexible, simple selfhosted homeserver as more limited, power-hungry but ready-to-go solutions such as Synology, Xpenelogy, Unraid or TrueNAS.</strong></h3>
<p align="center"><a href="README.md">Tip: a wider desktop view of this page.</a></p>
<p align="center">
  <a href="Justification.md">Why A Selfhosted Homeserver?</a> |
  <a href="https://www.docker.com/resources/what-container">Intro to microservices</a> |
  <a href="Recommendations.md">Hardware Recommendations</a> |
  <a href="https://github.com/zilexa/Homeserver/blob/master/README.md#requirements">How To Get Started?</a>
</p>

***

<h3 align="center">&bull; <strong>A fast, very low-maintenance, maximum energy efficient selfhosted cloud.</strong></h3>
<h3 align="center">&bull; <strong>Can be used for any selfhosted system (from home automation to password manager).</strong></h3>
<h3 align="center">&bull; <strong>Can also be deployed and run in the background on your HomePC/Workstation.</strong></h3>
<h3 align="center">&bull; <strong>Carefully selected hardware recommendations.</strong></h3>
<h3 align="center">&bull; <strong>Carefully selected Operating System and server tools.</strong></h3>
<h3 align="center">&bull; <strong>Preconfigured automatic nightly/monthly maintenance.</strong></h3>
<h3 align="center">&bull; <strong>Carefully selected services for file cloud, password manager, media downloads and more.</strong></h3>

<sub>Note: I had zero experience when I started and learned everything by googling, spending time on fora, reddit and in documentations and by hours and days of trial&error. I made lots of mistakes. Now, in case of disaster I will use the scripts in this repository myself to get up and running again. I am documenting this because I haven't found a single source online that provides _all necessary information_ to get up and running. Also, lot's of things have been carefully chosen after testing alternatives. You can save lots of time with this guide! :) [basic Linux commands](https://www.hostinger.com/tutorials/linux-commands).</sub>

## Features
* A file cloud using: _**FileRun**_ - Access and share your files from everywhere, sync your devices and enjoy your photo albums from any device, anywhere in the world. Fast and secure!
* A fantastic password manager: _**VaultWarden**_ - a.k.a Bitwarden, the best password manager available. 
* Your own Office Online/Google Docs: _**OnlyOffice**_ - integrates nicely with FileRun. 
* Your own browser sync: _**Firefox Sync Server**_ - your history, passwords, form fill info etc no longer shared with 3rd parties and easy to sync from laptop to phone.
* A highly secured reverse web proxy to be able to use all these features via your own domain like https://my.domain.cloud. 
* Your own ad-filtering or parental filtering dns server: _**AdGuard Home**_ - no more ads on any device within your network and even on your phone when you leave the house.
* Your own very fast VPN: _**Wireguard**_ - Your own VPN server and easy management of clients. To access services you do not want to expose publicly online.
* Your own paper scanning and organizing system _**Paperless-ng**_ - helps you to automatically archive your household administration and access documents easily.
* Your own media center server _**JellyFin**_ - Watch your series and movies on any smart TV or device. Also when you leave the home via VPN.
* Automatically follow and retrieve your favourite tv shows and movies _**Sonarr Radarr Bazarr QBittorrent**_ Because nobody can pay for every streaming service just to watch the few shows or movies they like. 
* Pretty dashboards to monitor your server _**Grafana, Prometheus**_ - Not necessary, but handy and with notifications. 
* Your own homepage to quickly access each service in a single webpage _**Plugsy**_ [See preview here](https://github.com/plugsy/core). 

For more details per service, [see here](https://github.com/zilexa/Homeserver/blob/master/services-apps-configuration.md). 

***

### Requirements
Regardless of your hardware (x86-64 or ARM, see [Hardware Recommendations](Recommendations.md), for the scripts in this guide to work, the following is required, otherwise you may need to change the install commands, build software, figure out how to configure email notifications etc: 

- Arch based OS
- AUR (Arch User Repository)
- Pamac to be able to install AUR packages
- Pacman to be able to install packages
- BTRFS filesystem - with or without swapfile (no swap partition)

**[Manjaro](https://manjaro.org/)** on x86-64 (Intel/AMD) is the recommended OS of choice and used for this guide. It does not matter which [desktop flavor](https://manjaro.org/download/) you choose. I use Gnome but power users might want to consider KDE instead. 

<sub>This guide used to be Ubuntu-based. All my laptops/PCs and my parents systems ran Ubuntu Budgie. After 2 years I switched to Manjaro (Gnome edition) and it is a delight!
A much better **out-of-the-box experience**, more **user-friendly** (also for setting up a server! This is reflected in my scripts, they are a lot smaller)  **lightweight**, **small footprint**, much better and up to date single source of **high quality documentation (Arch Wiki)** and **MUCH easier to install applications + keep up to date** than any Ubuntu system. Also, better out-of-the-box BTRFS support. For small, flexible homeservers and personal laptops I strongly believe BTRFS is the best filesystem. If you have more needs, look at XFS/ZFS. This guide will use BTRFS. </sub>

Step 0: get [the right hardware](Recommendations.md), most motherboards and CPUs are not designed for 24/7/365 continuous running, instead, they are designed for performance. 

***

### Step 1 - Install Operating System & Essential Tools
#### Step 1A -  How to install Manjaro? 
How to prep a USB stick: see [Manjaro First Steps > Using a Live System](https://manjaro.org/support/firststeps/). Further Instructions [here](https://github.com/zilexa/manjaro-gnome-post-install#quick-guide).

_Note_
* Requirement: select _BTRFS_ during setup with _no swap_, this allows you to later enable swapfile with hibernate support or zRAM.
* Requirement: Do not select "automatically login..", if you do, you will be faced with key-ring issues when using docker. Solveable but not covered by this guide.
* Consider using my [Manjaro Gnome Post-Install script](https://github.com/zilexa/manjaro-gnome-post-install). It is meant for both clients of your servers (laptops, PCs for you or your family) but also gives you a little headstart in this guide. You can always easily remove applications you do not need later, as the "App Store" of Manjaro is one of the best and fastest available in Linux world.

#### Step 1B. How to properly install Docker and essential tools?
_Turn your system into a modern server with 1 click with [prep_server.sh](https://github.com/zilexa/Homeserver/blob/master/prep-server.sh) to automatically or manually install essential tools, apply basic configuration + required stuff for optional docker services._

It is recommended to read through the [prep_server.sh](https://github.com/zilexa/Homeserver/blob/master/prep-server.sh) to get an idea what it does and why. 
It has been carefully created to install the tools required to run all aspects of your server (from docker to mainentance tasks). \
Official documentation is used to install tools correctly and all tools will be installed using the offical Manjaro package manager, a single package manager that keeps applications, OS and drivers up to date. 

Download and install it via: 
```
cd Downloads && wget https://raw.githubusercontent.com/zilexa/Homeserver/master/prep-server.sh
bash prep-server.sh
```
_Note_
> - A subvolume for Docker will be created --> allows extremely easy daily or hourly backups and recovery.
> - Installs Docker and follows [official best practices](https://docs.docker.com/engine/install/linux-postinstall/) to manage docker as non-root user (not rootless). 
> - Allows OS support to send emails (with minimal set of tools and configuration), several Docker containers and your maintenance tasks will need this.
> - Installs several other essential tools, essential for example for data migration, backups, maintenance.
> - Optional config files for a few services (will ask y/n before downloading).For example if you are going to use torrents, consider using the QBittorrent config file. The Organizr config might be nice and will save you lots of time building your own "Start" page.

***

### Step 2 - Filesystems and Folderstructure
This is the most time-consuming and complex part of creating your homeserver as there are many choices to be made, not just for your filesystem but also folderstructure. 
1. Check the [Filesystem Options](https://github.com/zilexa/Homeserver/tree/master/Filesystems-guide/Filesystems-options.md). Decide what is best for you. 
2. Follow the [Filesystems Guide](https://github.com/zilexa/Homeserver/tree/master/Filesystems-guide)

***

### Step 3. Data Migration
[Data Migration](https://github.com/zilexa/Homeserver/blob/master/Filesystems-guide/Data-Migration.md) - Move files to your server data pool.

***

### Step 4 - Network configuration
Before you can access your services outside of your home, [prepare your network](https://github.com/zilexa/Homeserver/blob/master/network-configuration.md) and get your own domain. 

***

### Step 5 - Docker Compose Guide - customisation and personalisation
[Docker Compose Guide](https://github.com/zilexa/Homeserver/tree/master/docker)
There are a lot of guides and docker-compose.yml files. Most of them are not complete or do not adhere to Docker best practices. A lot of hours have been spent on the yml file in this repository to ensure it follows best practices, does not contain unneccessary complexities and is as generic as possible, so that it can be published without security concerns. The .env file allows you to personalize your compose file through variables. 

_Note:_ 
> - The carefully written docker-compose.yml file is _**the unique part of this guide!**_. It can be tailored to your needs with Minimal Effort.
> - You cannot finalise your docker-compose without having a single path to your data and your media, covered in step 2.
> - The services you want to access via your own domain won't work until you have completed step 3.

### Step 6 - Configure your apps & services
The Docker guide (step 3) explains how to access your services. Configuring & using your services is not covered by this guide. 
The overview of Docker applications below will contain some foldable sections with hints. 
[Configure Apps & Services](https://github.com/zilexa/Homeserver/blob/master/services-apps-configuration.md) contains direct links to the documentation or homepage of each Docker app. 

***

### Step 7 - Configure & run Backups
Critical to enjoy the benefits of hosting your own server is the reliability of data storage and the ability to quickly recover a system (simply using your docker folder containing the folders you mount into containers). Follow the [Backup Guide](https://github.com/zilexa/Homeserver/tree/master/Backups-guide).

***

### Step 8 - Automatic Maintenance and optional manual maintenance
To keep your server purring quietly, without having to spend much or any time keeping it running, follow the [Maintenance Guide](https://github.com/zilexa/Homeserver/tree/master/Maintenance-guide) for regular cleanup, updates of server and docker images and filesystem/drive maintenance. 
