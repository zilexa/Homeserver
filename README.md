***
<p align="center">
  <a href="Justification.md">Why A Selfhosted Homeserver?</a> |
  <a href="https://www.docker.com/resources/what-container">Intro to microservices</a> |
  <a href="Recommendations.md">Hardware Recommendations</a> |
  <a href="#">How To Get Started?</a>
</p>



<p align="center">
  <ul>
  <li>one</li>
  <li>two</li>
  <li>three</li>
  </ul>
</p>
  
  


# The Modern Homeserver 
* A fast, very low-maintenance, energy efficient selfhosted cloud
* can be used for any selfhosted system (from home automation to password manager) 
### * Can also be deployed and run in the background on your HomePC/Workstation.
### * Carefully selected hardware recommendations.
### * Carefully selected Operating System and server tools.
### * Preconfigured automatic nightly/monthly maintenance.
### * Carefully selected services for file cloud, password manager, media downloads and more. 
  

***
Jan 11th 2021: I am updating this guide to support Manjaro (Arch based) Linux instead of Ubuntu. 
After working with Ubuntu for 2 years, I learned Manjaro has lots of advantages for normal users and for a home server. 
Expect lots of updates until end of January (my personal deadline to update & fully test everything). 
***

<sub>Note: I had zero experience when I started and learned everything by googling, spending time on fora, reddit and in documentations and by hours and days of trial&error. I made lots of mistakes. Now, in case of disaster I will use the scripts in this repository myself to get up and running again. I am documenting this because I haven't found a single source online that provides _all necessary information_ to get up and running. Also, lot's of things have been carefully chosen after testing alternatives. You can save lots of time with this guide! :)</sub>

## Features
_FileRun_ 
Access and share your files, enjoy your photo albums from any device, anywhere in the world. 
  - Faster and more user-friendly than NextCloud, Google Drive, Onedrive, Dropbox etc.
  - Not bloated with additional apps and features like NextCloud.
  - Not paid for with your privacy and crappy advertising like Google Drive. 
  - Free up to 10 users, unlimited guest users. 
-  


## How To Get Started With This Guide?
- The OS used is Ubuntu Budgie, because it is one of the most light-weight and extremely user-friendly of all Linux options. As this script is for beginners, it will help to have an intuitive OS to set everything up. Ofcourse, you can run the server headless (without UI, even without a monitor) . 
- **Please follow the [OS Installation Guide.](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script/blob/master/OS-installation/README.md) Step 3 (BtrFS filesystem) is required for this guide!**
- **In addition, consider running my post-install script [Ubuntu Budgie Post Install Script](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script). It's meant for home desktops and laptops but it also takes care of some OS essentials and generally recommended (by experts) btrfs subvolumes. At least use the parts of the script that make sense, especially setting up subvolumes.**
- Make sure you have a good text editor installed such as Pluma (`sudo apt install pluma`), this is done by the post-install script. 
- I had zero Linux experience when I started, so you don't need it, as long as you are ready to Google everything, especially some [basic Linux commands](https://www.hostinger.com/tutorials/linux-commands).

&nbsp;

## Steps to get up and running: 
### Step zero. Get the files
- Download this repository to your Downloads folder: Click the green "Code" button top left > Download as Zip. 
- Open a Terminal (CTRL+ALT+T) or hit the Budgie start button and start typing "Terminal" or "Tilix. 

NOTES:
  - Opening a script or textfile in Terminal (instead of a normal UI text editor like Pluma) can sometimes prevent you from messing up the file: `nano /path/to/file.sh` note in some cases you need elevated (root) privileges, to do that, prefix a command with `sudo`. 
  - **My system user account is called `asterix`, I use variables instead of personal names, but that is not always possible. Make sure you replace "asterix" with your systems username (and read Folder Structure! Because "asterix" is also very important in my folder structure).**


### Step 1 - Filesystem
[Prepare the filesystem](https://github.com/zilexa/Homeserver/tree/master/filesystem). Install fs tools, understand their goal, tailor to your needs.

### Step 2. Data Migration & Folder Structure
Move files to your server data pool and [create your folder structure](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure). Note my folder structure is simple.  

### Step 3 - Prepare server and docker
Continue to [Docker & server setup](https://github.com/zilexa/Homeserver/tree/master/docker) and use the bash script to automatically or manually install essential tools, apply basic configuration + required stuff for specific docker services. Get up and running in minutes via Docker Compose: _**this is the unique part of this guide, a complete and carefully built working Docker-Compose.yml file with variables.**_

### Step 4 - Configure your apps & services
The Docker guide (step 3) explains how to access your services. Configuring & using your services is not covered by this guide. 
The overview of Docker applications below will contain some foldable sections with hints. 
[Overview of Docker Apps](https://github.com/zilexa/Homeserver/blob/master/Applications-Overview.md) contains direct links to the documentation or homepage of each Docker app. 

### Step 5 - Configure & schedule Maintenance
Nightly [maintenance](https://github.com/zilexa/Homeserver/tree/master/maintenance-tasks) of your server such as cleanup, backup and disks protection tasks. 

### Step 6 - Configure & schedule Backups
Decide what will be your [Backup Strategy](https://github.com/zilexa/Homeserver/blob/master/backup-strategy/backupstrategy.md) and use the [Server Backup Guide](https://github.com/zilexa/Homeserver/tree/master/backup-strategy) to leverage the BTRFS filesystem to backup your @, @home, @docker subvolumes and your data subvolumes easily, while also having a timeline/timemachine snapshots of your data. 

