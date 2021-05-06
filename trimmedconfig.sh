#!/bin/bash
# Only for user SS who used the old version. 
#
# PREPARE FILESYSTEM & FOLDERSTRUCTURE FIRST! GO TO https://github.com/zilexa/Homeserver/tree/master/filesystem
sudo apt -y update
# ___________________
# System files go here
mkdir -p $HOME/docker/HOST/system/etc
# these files will be symlinked back to /system/etc.
## This way, 1 folder ($HOME/docker) contains system config, docker config and container volumes. 
# ___________________
cd $HOME/Downloads
# ____________________
# Install server tools
# ____________________

# Enable sharing desktop remotely - xRDP is faster than VNC but requires x11vnc to share current local desktop session
# ------------------------------
sudo apt -y install x11vnc
sudo apt -y install xrdp
## Get xrdp.ini config with desktop share via x11vnc enabled
wget -O /home/${USER}/docker/HOST/system/etc/xrdp/xrdp.ini https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/system/xrdp.ini
# link the system file to the system folder
sudo rm /etc/xrdp/xrdp.ini
sudo ln -s /home/${USER}/docker/HOST/system/etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini

## Autostart x11vnc at boot via systemd service file (only for x11vnc as xrdp already installed its systemd service during install)
sudo wget -O  /etc/systemd/system/x11vnc.service https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/system/x11vnc.service
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
echo "set mta=/usr/bin/msmtp" | tee -a $HOME/docker/HOST/system/etc/mail.rc
sudo ln -s /home/${USER}/docker/HOST/system/etc/mail.rc /etc/mail.rc
## Get simplest example config file for your external SMTP provider
sudo wget -O /home/${USER}/docker/HOST/system/etc/msmtprc https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/system/msmtprc

## link mailconfig to /etc/ - allow root to send emails
sudo chmod 644 /home/${USER}/docker/HOST/system/etc/msmtprc
sudo ln -s /home/${USER}/docker/HOST/system/etc/msmtprc /etc/msmtprc

# link copy of mailconfig to $HOME - allow current user (non-root) to send emails
sudo cp /home/${USER}/docker/HOST/system/etc/msmtprc /home/${USER}/docker/HOST/system/etc/user.msmtprc 
sudo ln -s /home/${USER}/docker/HOST/system/etc/user.msmtprc /home/${USER}/.msmtprc
## This is why a copy is needed, user needs to be owner and strict permissions. 
sudo chown ${USER}:${USER} $HOME/.msmtprc
sudo chmod 600 $HOME/.msmtprc

# Create aliases file, you need to put your email address in there
# This will be used by both root and current user. 
sudo tee -a /etc/aliases << EOF
default:myemail@address.com
EOF
#MANUALLY: put your email address in /etc/aliases
#MANUALLY: put your smtp provider details and credentials in both $HOME/docker/HOST/system/etc/msmtprc and user.msmtprc 

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
cd $HOME/Downloads
rm -rf snapraid*
# Get drive IDs
#ls -la /dev/disk/by-id/ | grep part1  | cut -d " " -f 11-20
# get SnapRAID config
sudo wget -O /home/${USER}/docker/HOST/snapraid/snapraid.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/snapraid/snapraid.conf
sudo ln -s /home/${USER}/docker/HOST/snapraid/snapraid.conf /etc/snapraid.conf
# MANUALLY: Create a root subvolume on your fastest disks named .snapraid, this wil contain snapraid content file. 
# MANUALLY: customise the $HOME/docker/HOST/snapraid/snapraid.conf file to your needs. 
# Get snapraid-btrfs script and make it executable
sudo wget -P /etc https://raw.githubusercontent.com/automorphism88/snapraid-btrfs/master/snapraid-btrfs
sudo chmod +x /etc/snapraid-btrfs
# Get snapraid-btrfs-runner
wget -O $HOME/docker/HOST/snapraid/master.zip https://github.com/fmoledina/snapraid-btrfs-runner/archive/refs/heads/master.zip
mv snapraid-btrfs-runner-master snapraid-btrfs-runner
unzip master.zip
rm master.zip


# Install snapper, required for snapraid-btrfs 
echo 'deb http://download.opensuse.org/repositories/filesystems:/snapper/xUbuntu_20.10/ /' | sudo tee /etc/apt/sources.list.d/filesystems:snapper.list
curl -fsSL https://download.opensuse.org/repositories/filesystems:snapper/xUbuntu_20.10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/filesystems_snapper.gpg > /dev/null
sudo apt -y update
sudo apt -y install snapper
sudo wget -O /etc/snapper/config-templates/default https://raw.githubusercontent.com/zilexa/Homeserver/master/maintenance/snapraid-btrfs/snapper/default
# MANUALLY: Create a root subvolume .snapshots within the subvolumes you want to protect. 


# Install btrbk
wget https://digint.ch/download/btrbk/releases/btrbk-0.31.2.tar.xz
tar xf btrbk*.tar.xz
mv btrbk*/ btrbk
cd btrbk
sudo make install
cd $HOME/Downloads
rm btrbk*.tar.xz
rm -rf $HOME/Downloads/btrbk
sudo ln -s /usr/sbin/btrbk /usr/local/bin/btrbk
## Get config and email script
wget -O $HOME/docker/HOST/btrbk/btrbk.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/btrbk/btrbk.conf
wget -O $HOME/docker/HOST/btrbk/btrbk-mail.sh https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/btrbk/btrbk-mail.sh
sudo ln -s /home/${USER}/docker/HOST/btrbk/btrbk.conf /etc/btrbk/btrbk.conf
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

# ______________________________________________________________
# Install Diun (Docker Image Update Notifier) & Pullio
# --------------------------------------------------------------
mkdir -P $HOME/docker/HOST/updater
cd $HOME/Downloads
wget -qO- https://github.com/crazy-max/diun/releases/download/v4.15.2/diun_4.15.2_linux_x86_64.tar.gz | tar -zxvf - diun
sudo cp diun /home/${USER}/docker/HOST/updater/
sudo ln -s /home/${USER}/docker/HOST/updater/diun /usr/local/bin/diun
rm diun_4.15.2_linux_x86_64.tar.gz
rm diun
# Get Diun conf file
wget -O $HOME/docker/HOST/updater/diun.yml https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/diun/diun.yml
sudo chmod 770 /home/${USER}/docker/HOST/updater/diun.yml
sudo mkdir /etc/diun
sudo chmod 770 /etc/diun
sudo ln -s /home/${USER}/docker/HOST/updater/diun.yml /etc/diun/diun.yml
# Install Pullio to auto update a few services
sudo wget -O /home/${USER}/docker/HOST/updater/pullio https://raw.githubusercontent.com/hotio/pullio/master/pullio.sh
sudo chmod +x /home/${USER}/docker/HOST/updater/pullio
sudo ln -s /home/${USER}/docker/HOST/updater/pullio /usr/local/bin/pullio


