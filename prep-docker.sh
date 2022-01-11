#!/bin/bash

echo "_________________________________________________________________________"
echo "              Create subvolume for Docker persistent data                "
echo "_________________________________________________________________________"
# Create a folder to temporarily map the BTRFS root
sudo mkdir /mnt/system
# Mount BTRFS root
SYSTEMDRIVE=$(df / | grep / | cut -d" " -f1)
sudo mount -o subvolid=5 $SYSTEMDRIVE /mnt/system
# create a root subvolume for docker
sudo btrfs subvolume create /mnt/system/@docker
## unmount root filesystem
sudo umount /mnt/system
# Get system fs UUID
fs_uuid=$(findmnt / -o UUID -n)
# Add @docker subvolume to fstab to mount at boot
sudo tee -a /etc/fstab &>/dev/null << EOF
# Mount the BTRFS root subvolume @userdata
UUID=${fs_uuid} /mnt/docker  btrfs   defaults,noatime,subvol=@docker,compress-force=zstd:1  0  0
EOF

# Create folder for server maintenance scripts
mkdir -p $HOME/docker/HOST/system/etc


echo "______________________________________________________"
echo "Powertop + systemd service to manage power consumption"
echo "______________________________________________________"
## Create a service file to run powertop --auto-tune at boot
sudo tee -a /etc/systemd/system/powertop.service << EOF
[Unit]
Description=Powertop tunings

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/powertop --auto-tune

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


echo "____________________________________________________________"
echo "Run-if-today: simplify scheduling of weekly or monthly tasks"
echo "____________________________________________________________"
sudo wget -O /usr/bin/run-if-today https://raw.githubusercontent.com/xr09/cron-last-sunday/master/run-if-today
sudo chmod +x /usr/bin/run-if-today

echo "_________________________________________________________"
echo "Configure linux email notifications without heavy postfix"
echo "_________________________________________________________"
# ----------------------------
sudo pacman -S --noconfirm msmtp
sudo pacman -S --noconfirm s-nail
# link sendmail to msmtp
sudo ln -s /usr/bin/msmtp /usr/bin/sendmail
sudo ln -s /usr/bin/msmtp /usr/sbin/sendmail
# set msmtp as mta
echo "set mta=/usr/bin/msmtp" | sudo tee -a /etc/mail.rc
## Get config file, MANUALLY add your smtp provider credentials
sudo wget -O /etc/msmtprc https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/system/etc/msmtprc
# Create aliases file, MANUALLY edit file and replace with your emailaddress 
sudo tee -a /etc/aliases << EOF
default:myemail@address.com
EOF

echo "______________________________________________________"
echo "btrbk - flexible tool to automate snapshots & backups "
echo "______________________________________________________"
sudo pamac install --no-confirm btrbk
## Get config and email script
mkdir -p $HOME/docker/HOST/btrbk
wget -O $HOME/docker/HOST/btrbk/btrbk.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/btrbk/btrbk.conf
wget -O $HOME/docker/HOST/btrbk/btrbk-mail.sh https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/btrbk/btrbk-mail.sh
sudo ln -s $HOME/docker/HOST/btrbk/btrbk.conf /etc/btrbk/btrbk.conf
# MANUALLY configure the $HOME/docker/HOST/btrbk/btrbk.conf to your needs

echo "______________________________________________________"
echo "nocache and grsync - secure file copy tools           "
echo "______________________________________________________"
echo "nocache - handy when moving lots of files at once in the background, without filling up cache and slowing down the system."
sudo pamac install --no-confirm nocache
echo "Grync - friendly UI for rsync"
sudo pacman -S --noconfirm grsync
sudo pacman -S --noconfirm lm_sensors
echo "______________________________________________________"
echo "Install lm-sensors & detect system sensors for Netdata"
echo "______________________________________________________"

sudo sensors-detect --auto



echo "=============================================================="
echo "                                                              "
echo "  The following tools have been installed (& configured!)     "
echo "                                                              "
echo "  POWERTOP    - system service to optimise power management   "
echo "  MSMTP       - to allow the system to send emails            " 
echo "  BTRBK       - THE tool to automate backups                  "
echo "  LMSENSORS   - for the OS to access its diagnostic sensors   "
echo "  NOCACHE     - allows background rsyncing                    "
echo "  Grsync      - Friendly ui for rsync                         "
echo "                                                              "
echo "to configure email, desktop share, backups or NFSv4.2:        "
echo "Go to: https://github.com/zilexa/Homeserver                   "
echo "=============================================================="
echo "                                                              " 
read -p " Hit a key to continue...                                  "
echo "                                                              " 
echo "                                                              " 
echo "---------------------------------------------------"
read -p "Install SNAPRAID-BTRFS for parity-based backups?" answer
case ${answer:0:1} in
    y|Y )
        echo "Installing required tools: snapraid, Snapraid-btrfs, snapraid-btrfs-runner mailscript and snapper.."
        sudo pamac install --no-confirm snapraid 
        sudo pamac install --no-confirm snapraid-btrfs-git
        # Install snapraid-btrfs-runner
        wget -O $HOME/docker/HOST/snapraid/master.zip https://github.com/fmoledina/snapraid-btrfs-runner/archive/refs/heads/master.zip
        unzip $HOME/docker/HOST/snapraid/master.zip
        mv $HOME/docker/HOST/snapraid/snapraid-btrfs-runner-master $HOME/docker/HOST/snapraid/snapraid-btrfs-runner
        rm $HOME/docker/HOST/snapraid/master.zip
        # Install snapper, required for snapraid-btrfs 
        sudo pacman -S --no-confirm snapper-gui
        # Get snapper default template
        sudo wget -O /etc/snapper/config-templates/default https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/snapraid/snapper/default
        # get SnapRAID config
        sudo wget -O $HOME/docker/HOST/snapraid/snapraid.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/snapraid/snapraid.conf
        sudo ln -s $HOME/docker/HOST/snapraid/snapraid.conf /etc/snapraid.conf
        # MANUALLY: Create a root subvolume on your fastest disks named .snapraid, this wil contain snapraid content file. 
        # MANUALLY: customise the $HOME/docker/HOST/snapraid/snapraid.conf file to your needs. 
        # MANUALLY: follow instructions in the guide 
        # Get drive IDs
        #ls -la /dev/disk/by-id/ | grep part1  | cut -d " " -f 11-20
    ;;
    * )
        echo "Skipping Snapraid, Snapraid-BTRFS, snapraid-btrfs-runner and snapper"
    ;;
esac

echo "____________________________________________________"
echo "Docker, docker-compose, bash completion for compose " 
echo "____________________________________________________"
sudo pacman -S --noconfirm docker
sudo pacman -S --noconfirm docker-compose
systemctl --user enable docker
systemctl --user start docker

echo "-----------------"
echo "Configure Docker "
echo "-----------------"
# Make docker-compose file an executable file and add the current user to the docker container
#sudo chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker ${USER}
# Create the docker folder
sudo mkdir -p $HOME/docker
sudo setfacl -Rdm g:docker:rwx ~/docker
sudo chmod -R 755 ~/docker
# Get environment variables to be used by Docker (i.e. requires TZ in quotes)
sudo wget -O $HOME/docker/.env https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/.env
# Get docker compose file
sudo wget -O $HOME/docker/docker-compose.yml https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/docker-compose.yml

echo "__________________________________________________________________________"
echo "Diun (notify of docker apps updates) & Pullio (auto-install selected apps)"
echo "__________________________________________________________________________"
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

echo "============================================================================"
echo "                                                                            "
echo "  Docker is ready to go!                                                    "
echo "                                                                            "
echo "If you need any of the following apps, hit yes to take care of              "
echo "their required setup before running compose:                                "
echo "----------------------------------------------------------------------------"
echo "Prepare for Scrutiny: a nice webUI to monitor your SSD & HDD drives health? (recommend: y)" 
read -p "y or n ?" answer
case ${answer:0:1} in
    y|Y )
        # Scrutiny (S.M.A.R.T. disk health monitoring)
        # --------------------------------------------
        sudo mkdir -p $HOME/docker/scrutiny/config
        sudo chown ${USER}:${USER} $HOME/docker/scrutiny/config
        wget -O $HOME/docker/scrutiny/config/collector.yaml https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/scrutiny/collector.yaml
        sudo chmod 644 $HOME/docker/scrutiny/config/collector.yaml
        echo "Done, Before running compose, manually adjust the file /docker/scrutiny/config/collector.yaml to the number of nvme drives you have."
        read -p "hit a button to continue..."
    ;;
    * )
        echo "SKIPPED downloading config yml file.."
    ;;
esac


echo "--------------------------------------------------------------------------------------------------------------"
echo "Download recommended/best-practices configuration for QBittorrent: to download media, torrents? (recommend: y)" 
read -p "y or n ?" answer
case ${answer:0:1} in
    y|Y )
        sudo mkdir -p $HOME/docker/qbittorrent/config
        sudo chown ${USER}:${USER} $HOME/docker/qbittorrent/config
        wget -O $HOME/docker/qbittorrent/config/qBittorrent.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/qbittorrent/config/qBittorrent.conf
        sudo chmod 644 $HOME/docker/qbittorrent/config/qBittorrent.conf
    ;;
    * )
        echo "SKIPPED downloading QBittorrent config file.."
    ;;
esac


echo "---------------------------------------------------------------------------------------------"
echo "Download preconfigured Organizr config: your portal to all your apps and services? (optional)" 
read -p "y or n ?" answer
case ${answer:0:1} in
    y|Y )
        # Not sure if this works, it will download my config, a homepage with all services. MANUALLY via the Organizr settings, add the credentials and change the ip:port for each.
        # Just to get you started with a homepage instead of the basic blank stuff. 
        # MANUALLY stop the container, delete these files and restart if Organizr doesn't work. 
        sudo mkdir -p $HOME/docker/organizr/www/organizr/api/config
        sudo chown -R ${USER}:${USER} $HOME/docker/organizr
        wget -O $HOME/docker/organizr/www/organizr/api/config/config.php https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/organizr/www/organizr/api/config/config.php
        wget -O $HOME/docker/organizr/www/organizr/organizrdb.db https://github.com/zilexa/Homeserver/blob/master/docker/organizr/www/organizr/organizrdb.db?raw=true
    ;;
    * )
        echo "SKIPPED downloading Organizr pre-configuration.."
    ;;
esac


echo "                                                                               "        
echo "==============================================================================="
echo "                                                                               "  
echo "All done! Please log out/in first, before running Docker (reboot not required)."
echo "                                                                               "  
echo "==============================================================================="
