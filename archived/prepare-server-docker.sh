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
# Install packages required to build applications from source
sudo apt -y install build-essential

echo "___________________________"
echo "SSH: remote terminal & SFTP"
echo "___________________________"
sudo apt -y install ssh
sudo systemctl enable --now ssh
sudo ufw allow ssh 

echo "______________________________________________________"
echo "Powertop + systemd service to manage power consumption"
echo "______________________________________________________"
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

echo "__________________________________________________________"
echo "NFSv4.2: fastest solution for local network folder sharing"
echo "__________________________________________________________"
sudo apt -y install nfs-server

echo "_____________________________________________________"
echo "xrdp & x11nvc: fastest solution to share your desktop"
echo "_____________________________________________________"
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

echo "____________________________________________________________"
echo "Run-if-today: simplify scheduling of weekly or monthly tasks"
echo "____________________________________________________________"
sudo wget -O /usr/bin/run-if-today https://raw.githubusercontent.com/xr09/cron-last-sunday/master/run-if-today
sudo chmod +x /usr/bin/run-if-today

echo "_________________________________________________________"
echo "Configure linux email notifications without heavy postfix"
echo "_________________________________________________________"
# ----------------------------
sudo apt -y install msmtp s-nail
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
mkdir -p $HOME/docker/HOST/btrbk
wget -O $HOME/docker/HOST/btrbk/btrbk.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/btrbk/btrbk.conf
wget -O $HOME/docker/HOST/btrbk/btrbk-mail.sh https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/btrbk/btrbk-mail.sh
sudo ln -s $HOME/docker/HOST/btrbk/btrbk.conf /etc/btrbk/btrbk.conf
# MANUALLY configure the $HOME/docker/HOST/btrbk/btrbk.conf to your needs

echo "______________________________________________________"
echo "nocache and grsync - secure file copy tools           "
echo "______________________________________________________"
echo "nocache - handy when moving lots of files at once in the background, without filling up cache and slowing down the system."
sudo apt -y install nocache
echo "Grync - friendly UI for rsync"
sudo apt -y install grync

echo "______________________________________________________"
echo "Install lm-sensors & detect system sensors for Netdata"
echo "______________________________________________________"
sudo apt -y install lm-sensors
sudo sensors-detect --auto
echo "--------------------------------------"
echo "Install Netdata - monitoring dashboard"
echo "______________________________________"
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait --stable-channel


echo "=============================================================="
echo "                                                              "
echo "  The following tools have been installed (& configured!)     "
echo "                                                              "
echo "  SSH         - secure terminal & sftp access                 "
echo "  X11VNC,XRDP - fastest remote desktop sharing                "
echo "  POWERTOP    - system service to optimise power management   "
echo "  NFSv4.2     - the fastest network protocol to share folders "
echo "  MSMTP       - to allow the system to send emails            " 
echo "  BTRBK       - THE tool to automate backups                  "
echo "  LMSENSORS   - for the OS to access its diagnostic sensors   "
echo "  NETDATA     - monitoring dashboard (needs LMSENSORS)        "
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
wget -qO - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt -y update
sudo apt -y install docker-ce docker-ce-cli containerd.io
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo curl -L https://raw.githubusercontent.com/docker/compose/1.26.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "-----------------"
echo "Configure Docker "
echo "-----------------"
# Make docker-compose file an executable file and add the current user to the docker container
sudo chmod +x /usr/local/bin/docker-compose
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


echo "-------------------------------------------------------------------------------------------------"
echo "Prepare for elasticsearch: allow indexing and searching through contents of files? (recommend: n)" 
read -p "y or n ?" answer
case ${answer:0:1} in
    y|Y )
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
    ;;
    * )
        echo "SKIPPED prepping elasticsearch.."
    ;;
esac


echo "---------------------------------------------------------------------------"
echo "Disable Ubuntu own DNS resolver, it blocks port 53? (recommend: y)         "
echo "Required if you will run your own DNS server (AdGuardHome,PiHole, Unbound) " 
read -p "y or n ?" answer
case ${answer:0:1} in
    y|Y )
        # Required on Ubuntu systems if you will run your own DNS resolver and/or adblocking DNS server.
        # ---------------------------------------------
        sudo systemctl disable systemd-resolved.service
        sudo systemctl stop systemd-resolved.service
        echo "dns=default" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
        echo "-------------------------------------------------------------------------------"
        echo "You need to do the next step yourself, please read carefully before continuing!"
        echo "-------------------------------------------------------------------------------"
        echo "A text file will open when you hit a key. Please do the following:             "
        echo "Move dns=default to the [MAIN] section by manually deleting it and typing it.  "
        echo "You can also copy with mouse, delete it and paste it below [MAIN]              "
        echo "AFTER you have done that, save changes via CTRL+O, exit the editor via CTRL+X. "
        echo "                                                                               "
        read -p "ready to do this? Hit a key..."
        sudo nano /etc/NetworkManager/NetworkManager.conf
        sudo rm /etc/resolv.conf
        sudo systemctl restart NetworkManager.service
    ;;
    * )
        echo "SKIPPED disabling of Ubuntu DNS resolver.."
    ;;
esac


echo "                                                                               "        
echo "==============================================================================="
echo "                                                                               "  
echo "All done! Please log out/in first, before running Docker (reboot not required)."
echo "                                                                               "  
echo "==============================================================================="
