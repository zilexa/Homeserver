#!/bin/bash
# PREPARE FILESYSTEM & FOLDERSTRUCTURE FIRST! GO TO https://github.com/zilexa/Homeserver/tree/master/filesystem
# ___________________
# System files go here
mkdir -p $HOME/docker/HOST/system/etc
# these files will be symlinked back to /system/etc.
## This way, 1 folder ($HOME/docker) contains system config, docker config and container volumes. 
# ___________________
sudo apt -y update
cd $HOME/Downloads
# ____________________
# Install server tools
# ____________________
# SSH - remote terminal & SFTP
# ---
sudo apt -y install ssh
sudo systemctl enable --now ssh
sudo ufw allow ssh 

# Install Powertop - required to autotune power management
# ---------------
sudo apt -y install powertop
## Create a service file to run powertop --auto-tune at boot
sudo tee -a /etc/systemd/system/powertop.service << EOF
[Unit]
Description=PowerTOP auto tune

[Service]
Type=idle
Environment="TERM=dumb"
ExecStart=/usr/sbin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
EOF
## Enable the service
sudo systemctl daemon-reload
sudo systemctl enable powertop.service
## Tune system now
sudo powertop --auto-tune
## Start the service
sudo systemctl start powertop.service

# NFS Server - 15%-30% faster than SAMBA/SMB shares
# ----------
sudo apt -y install nfs-server

# Enable sharing desktop remotely - xRDP is faster than VNC but requires x11vnc to share current local desktop session
# ------------------------------
sudo apt -y install x11vnc
sudo apt -y install xrdp
## Get xrdp.ini config with desktop share via x11vnc enabled
wget -O $HOME/docker/HOST/system/etc/xrdp/xrdp.ini https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/system/etc/xrdp/xrdp.ini
# link the system file to the system folder
sudo rm /etc/xrdp/xrdp.ini
sudo ln -s $HOME/docker/HOST/system/etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini

## Autostart x11vnc at boot via systemd service file (only for x11vnc as xrdp already installed its systemd service during install)
sudo wget -O  /etc/systemd/system/x11vnc.service https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/system/etc/x11vnc.service
sudo systemctl daemon-reload
sudo systemctl enable x11vnc
sudo systemctl start x11vnc

# install run-if-today to simplify scheduling weekly or monthly tasks (example: every last sunday of the month)
# --------------------
sudo wget -O /usr/bin/run-if-today https://raw.githubusercontent.com/xr09/cron-last-sunday/master/run-if-today
sudo chmod +x /usr/bin/run-if-today

# Enable system to send emails without using postfix
# ----------------------------
sudo apt -y install msmtp s-nail
# link sendmail to msmtp
sudo ln -s /usr/bin/msmtp /usr/bin/sendmail
sudo ln -s /usr/bin/msmtp /usr/sbin/sendmail
echo "set mta=/usr/bin/msmtp" | sudo tee -a /etc/mail.rc
## Get simplest example config file for your external SMTP provider
sudo wget -O /etc/msmtprc https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/system/etc/msmtprc

# Create aliases file, you need to put your email address in there. 
sudo tee -a /etc/aliases << EOF
default:myemail@address.com
EOF
#MANUALLY: put your email address in /etc/aliases
#MANUALLY: put your smtp provider details and credentials in etc/msmtprc

# install SnapRAID
# ----------------
sudo apt -y install gcc git make
wget https://github.com/amadvance/snapraid/releases/download/v11.5/snapraid-11.5.tar.gz
tar xzvf snapraid*.tar.gz
cd snapraid-11.5/
./configure
sudo make
sudo make check
sudo make install
sudo ln -s /usr/bin/snapraid /usr/local/bin/snapraid
cd $HOME/Downloads
rm -rf snapraid*
# Get drive IDs
#ls -la /dev/disk/by-id/ | grep part1  | cut -d " " -f 11-20
# get SnapRAID config
sudo wget -O $HOME/docker/HOST/snapraid/snapraid.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/snapraid/snapraid.conf
sudo ln -s $HOME/docker/HOST/snapraid/snapraid.conf /etc/snapraid.conf
# MANUALLY: Create a root subvolume on your fastest disks named .snapraid, this wil contain snapraid content file. 
# MANUALLY: customise the $HOME/docker/HOST/snapraid/snapraid.conf file to your needs. 
# Get snapraid-btrfs script and make it executable
sudo wget -O /usr/bin/snapraid-btrfs https://raw.githubusercontent.com/automorphism88/snapraid-btrfs/master/snapraid-btrfs
sudo chmod +x /usr/bin/snapraid-btrfs
sudo ln -s /usr/bin/snapraid-btrfs /usr/local/bin/snapraid-btrfs
# Get snapraid-btrfs-runner
wget -O $HOME/docker/HOST/snapraid/master.zip https://github.com/fmoledina/snapraid-btrfs-runner/archive/refs/heads/master.zip
unzip $HOME/docker/HOST/snapraid/master.zip
mv $HOME/docker/HOST/snapraid/snapraid-btrfs-runner-master $HOME/docker/HOST/snapraid/snapraid-btrfs-runner
rm $HOME/docker/HOST/snapraid/master.zip


# Install snapper, required for snapraid-btrfs 
sudo apt -y install snapper
sudo wget -O /etc/snapper/config-templates/default https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/snapraid/snapper/default
# MANUALLY: follow instructions in the guide 

# Install btrbk
wget https://digint.ch/download/btrbk/releases/btrbk-0.31.2.tar.xz
tar xf btrbk*.tar.xz
mv btrbk*/ btrbk
cd btrbk
sudo make install
cd $HOME/Downloads
rm btrbk*.tar.xz
rm -rf $HOME/Downloads/btrbk
sudo ln -s /usr/bin/btrbk /usr/local/bin/btrbk
## Get config and email script
wget -O $HOME/docker/HOST/btrbk/btrbk.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/btrbk/btrbk.conf
wget -O $HOME/docker/HOST/btrbk/btrbk-mail.sh https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/btrbk/btrbk-mail.sh
sudo ln -s $HOME/docker/HOST/btrbk/btrbk.conf /etc/btrbk/btrbk.conf
# MANUALLY configure the $HOME/docker/HOST/btrbk/btrbk.conf to your needs

# install nocache - required to move files from pool to pool-nocache with rsync
# ---------------
sudo apt -y install nocache

echo "========================================================================="
echo "                                                                         "
echo "               The following tools have been installed:                  "
echo "                                                                         "
echo "                SSH - secure terminal & sftp connection                  "
echo "           X11VNC & XRDP - fastest remote desktop sharing                "
echo "           POWERTOP - to optimise power management at boot               "
echo "          LMSENSORS - for the OS to access its diagnostic sensors        "
echo "           NFS - the fastest network protocol to share folders           "
echo "           MSMTP - to allow the system to send emails                    " 
echo "               BTRBK - THE tool to automate backups                      "
echo "                 SNAPRAID-BTRFS - backup via parity                      "
echo "                                                                         "
echo "========================================================================="
echo "to configure NFSv4.2 with server-side copy:"
echo "(save this URL and hit a key to continue): "
read -p "https://github.com/zilexa/Homeserver/tree/master/network%20share%20(NFSv4.2)"
echo "==============================================================="
echo "                                                               "
echo "PiVPN install wizard will be downloaded & started, a few hints:"
echo "1) Select Wireguard.                                           "
echo "2) Plan on running AdGuard Home with/without Unbound?          "
echo "Then fill in your own server LAN IP as the DNS server.         "
echo "If not, e select Quad9 or similar DNS server.                  "
echo "---------------------------------------------------------------"
read -p "hit a key to start... "
# PiVPN ~ Install & configure wizard
curl -L https://install.pivpn.io | bash
echo "==============================================================="
echo "                                                               "
echo "Netdata monitoring tool install wizard will start              "
echo "---------------------------------------------------------------"
read -p  "hit a key to start... "
# Netdata ~ install wizard
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# ______________________________________________________________
# Install Docker 
# --------------------------------------------------------------
# Install Docker, Docker-Compose and bash completion for Compose
wget -qO - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt -y update
sudo apt -y install docker-ce docker-ce-cli containerd.io
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo curl -L https://raw.githubusercontent.com/docker/compose/1.26.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# ______________________________________________________________
# Configure Docker
# --------------------------------------------------------------
# Make docker-compose file an executable file and add the current user to the docker container
sudo chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker ${USER}

# Create the docker folder
sudo mkdir -p $HOME/docker
sudo setfacl -Rdm g:docker:rwx ~/docker
sudo chmod -R 755 ~/docker
# Get environment variables to be used by Docker (i.e. requires TZ in quotes)
sudo wget -O /home/{$USER}/docker/.env https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/.env

# Get docker compose file
sudo wget -O /home/{USER}/docker/docker-compose.yml https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/docker-compose.yml

# ______________________________________________________________
# Install Diun (Docker Image Update Notifier) & Pullio
# --------------------------------------------------------------
mkdir -P $HOME/docker/HOST/updater
cd $HOME/Downloads
wget -qO- https://github.com/crazy-max/diun/releases/download/v4.15.2/diun_4.15.2_linux_x86_64.tar.gz | tar -zxvf - diun
sudo cp diun $HOME/docker/HOST/updater/
sudo ln -s $HOME/docker/HOST/updater/diun /usr/local/bin/diun
rm diun*.gz
rm diun
# Get Diun conf file
wget -O $HOME/docker/HOST/updater/diun.yml https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/diun/diun.yml
sudo chmod 770 $HOME/docker/HOST/updater/diun.yml
sudo mkdir /etc/diun
sudo chmod 770 /etc/diun
sudo ln -s $HOME/docker/HOST/updater/diun.yml /etc/diun/diun.yml
# Install Pullio to auto update a few services
sudo wget -O $HOME/docker/HOST/updater/pullio https://raw.githubusercontent.com/hotio/pullio/master/pullio.sh
sudo chmod +x $HOME/docker/HOST/updater/pullio
sudo ln -s $HOME/docker/HOST/updater/pullio /usr/local/bin/pullio


# __________________________________________________________________________________
# Docker per-application configuration, required before starting the apps container
# ----------------------------------------------------------------------------------

# Scrutiny (S.M.A.R.T. disk health monitoring)
# --------------------------------------------
# Required to scan NVME drives. MANUALLY ADJUST TO YOUR SYSTEM
sudo mkdir -p $HOME/docker/scrutiny/config
sudo chown ${USER}:${USER} $HOME/docker/scrutiny/config
wget -O $HOME/docker/scrutiny/config/collector.yaml https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/scrutiny/collector.yaml
sudo chmod 644 $HOME/docker/scrutiny/config/collector.yaml

# QBittorrent
# -----------
sudo mkdir -p $HOME/docker/qbittorrent/config
sudo chown ${USER}:${USER} $HOME/docker/qbittorrent/config
wget -O $HOME/docker/qbittorrent/config/qBittorrent.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/qbittorrent/config/qBittorrent.conf
sudo chmod 644 $HOME/docker/qbittorrent/config/qBittorrent.conf

# Organizr
# --------
# Not sure if this works, it will download my config, a homepage with all services. MANUALLY via the Organizr settings, add the credentials and change the ip:port for each.
# Just to get you started with a homepage instead of the basic blank stuff. 
# MANUALLY stop the container, delete these files and restart if Organizr doesn't work. 
sudo mkdir -p $HOME/docker/organizr/www/organizr/api/config
sudo chown -R ${USER}:${USER} $HOME/docker/organizr
wget -O $HOME/docker/organizr/www/organizr/api/config/config.php https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/organizr/www/organizr/api/config/config.php
wget -O $HOME/docker/organizr/www/organizr/organizrdb.db https://github.com/zilexa/Homeserver/blob/master/docker/organizr/www/organizr/organizrdb.db?raw=true

# FileRun & ElasticSearch ~ requirements
# ---------------------------------------------
# Create folder and set permissions
sudo mkdir -p $HOME/docker/filerun/esearch
sudo chown -R $USER:$USER $HOME/docker/filerun/esearch
sudo chmod 755 $HOME/docker/filerun/esearch
# IMPORTANT! Should be the same user:group as the owner of the personal data you access via FileRun!
sudo mkdir -p $HOME/docker/filerun/html
sudo chown -R $USER:$USER $HOME/docker/filerun/html
sudo chmod 755 $HOME/docker/filerun/html
# Change OS virtual mem allocation as it is too low by default for ElasticSearch
sudo sysctl -w vm.max_map_count=262144
# Make this change permanent
sudo sh -c "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf"

# Required on Ubuntu systems if you will run your own DNS resolver and/or adblocking DNS server.
# ---------------------------------------------
sudo systemctl disable systemd-resolved.service
sudo systemctl stop systemd-resolved.service
echo "dns=default" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
echo "----------------------------------------------------------------------------------"
echo "To support running your own DNS server on Ubuntu, via docker or bare, disable Ubuntu's built in DNS resolver now."
echo "----------------------------------------------------------------------------------"
echo "Move dns=default to the [MAIN] section by manually deleting it and typing it."
echo "AFTER you have done that, save changes via CTRL+O, exit the editor via CTRL+X."
read -p "ready to do this? Hit a key..."
sudo nano /etc/NetworkManager/NetworkManager.conf
sudo rm /etc/resolv.conf
sudo systemctl restart NetworkManager.service
echo "All done, if there were errors, go through the script manually, find and execute the failed commands."
