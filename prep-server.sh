#!/bin/bash
# >>> DO NOT USE THIS FILE ON UBUNTU. USE /ARCHIVED/ INSTEAD. THIS FILE HAS BEEN ADJUSTED FOR MANJARO LINUX. <<<

echo "______________________________________________________"
echo "        MANAGE POWER CONSUMPTION AUTOMATICALLY        "
echo "         always run Powertop autotune at boot         "
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


echo "____________________________________________"
echo "                APPLICATIONS                "
echo "                server tools                "
echo "____________________________________________"
echo "                   BTRBK                    "
echo "--------------------------------------------"
echo "Swiss handknife-like tool to automate snapshots & backups of personal data" 
# available in the Arch User Repository (AUR) thus installed via Pamac. Will be automatically updated just like official repository packages. 
sudo pamac install --no-confirm btrbk

echo "               RUN-IF-TODAY                 "
echo "--------------------------------------------"
echo "simplify scheduling of weekly/monthly tasks"
sudo wget -O /usr/bin/run-if-today https://raw.githubusercontent.com/xr09/cron-last-sunday/master/run-if-today
sudo chmod +x /usr/bin/run-if-today

echo "                   NOCACHE                  "
echo "--------------------------------------------"
echo "handy when moving lots of files at once in the background, without filling up cache and slowing down the system."
# available in the Arch User Repository (AUR) thus installed via Pamac. Will be automatically updated just like official repository packages. 
sudo pamac install --no-confirm nocache

echo "                    GRSYNC                  "
echo "--------------------------------------------"
echo "Friendly UI for rsync"
sudo pamac install --no-confirm grsync

echo "                LM_SENSORS                  "
echo "--------------------------------------------"
echo "to be able to read out all sensors" 
sudo pamac install --no-confirm lm_sensors
sudo sensors-detect --auto

echo "                 MERGERFS                  "
echo "-------------------------------------------"
echo "pool drives to make them appear as 1 without raid"
# available in the Arch User Repository (AUR) thus installed via Pamac. Will be automatically updated just like official repository packages. 
sudo pamac install --no-confirm mergerfs


echo "______________________________________________"
echo "                                              " 
echo "               DOCKER SUBVOLUME               "
echo "______________________________________________"
echo "      on-demand systemdrive mountpoint     "
echo "-------------------------------------------"
# The MANJARO GNOME POST INSTALL SCRIPT has created a mountpoint for systemdrive. If that script was not used, create the mountpoint now:
#Get device path of systemdrive, for example "/dev/nvme0n1p2" via #SYSTEMDRIVE=$(df / | grep / | cut -d" " -f1)
if sudo grep -Fq "/mnt/disks/systemdrive" /etc/fstab; then echo already added by post-install script; 
else 
# Add an ON-DEMAND mountpoint in FSTAB for the systemdrive, to easily do a manual mount when needed (via "sudo mount /mnt/disks/systemdrive")
sudo mkdir -p /mnt/disks/systemdrive
# Get the systemdrive UUID
fs_uuid=$(findmnt / -o UUID -n)
# Add mountpoint to FSTAB
sudo tee -a /etc/fstab &>/dev/null << EOF

# Allow easy manual mounting of btrfs root subvolume                         
UUID=${fs_uuid} /mnt/disks/systemdrive  btrfs   subvolid=5,defaults,noatime,noauto  0  0
EOF
fi

sudo mount -a

echo "              Docker subvolume              "
echo "--------------------------------------------"
echo "create subvolume for Docker persistent data "
# Temporarily Mount filesystem root
sudo mount /mnt/disks/systemdrive
# create a root subvolume for docker
sudo btrfs subvolume create /mnt/disks/systemdrive/@docker
## unmount root filesystem
sudo umount /mnt/disks/systemdrive
# Create mountpoint, to be used by fstab
mkdir $HOME/docker
# Get system fs UUID, to be used for next command
fs_uuid=$(findmnt / -o UUID -n)
# Add @docker subvolume to fstab to mount on mountpoint at boot
sudo tee -a /etc/fstab &>/dev/null << EOF

# Mount @docker subvolume
UUID=${fs_uuid} $HOME/docker  btrfs   subvol=@docker,defaults,noatime,x-gvfs-hide,compress-force=zstd:1  0  0
EOF
sudo mount -a
sudo chown ${USER}:${USER} $HOME/docker
sudo chmod -R 755 $HOME/docker
#sudo setfacl -Rdm g:docker:rwx $HOME/docker


echo "______________________________________________________________________"
echo "                                                                      " 
echo " GET THE homeserver guide DOCKER COMPOSE FILE and MAINTENANCE SCRIPTS "
echo "______________________________________________________________________"
cd $HOME/Downloads
echo "         compose yml and env file           "
echo "--------------------------------------------"
wget -O $HOME/docker/.env https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/.env
wget -O $HOME/docker/docker-compose.yml https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/docker-compose.yml

echo "         server maintenance scripts         "
echo "--------------------------------------------"
curl -L https://api.github.com/repos/zilexa/Homeserver/tarball | tar xz --wildcards "*/docker/HOST/" --strip-components=1
mv $HOME/Downloads/docker/HOST $HOME/docker/
rm -r $HOME/Downloads/docker

echo "      BTRBK config and mail script          "
echo "--------------------------------------------"
mkdir -p $HOME/docker/HOST/btrbk
wget -O $HOME/docker/HOST/btrbk/btrbk.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/btrbk/btrbk.conf
wget -O $HOME/docker/HOST/btrbk/btrbk-mail.sh https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/btrbk/btrbk-mail.sh
sudo ln -s $HOME/docker/HOST/btrbk/btrbk.conf /etc/btrbk/btrbk.conf
# MANUALLY configure the $HOME/docker/HOST/btrbk/btrbk.conf to your needs

echo "PULLIO script to auto update certain services"
echo "--------------------------------------------"
# Should only be used for selected services. For all others, Diun (docker container) is used to notify only instead of auto-update.
mkdir -p $HOME/docker/HOST/updater/pullio
sudo wget -O $HOME/docker/HOST/updater/pullio https://raw.githubusercontent.com/hotio/pullio/master/pullio.sh
sudo chmod +x $HOME/docker/HOST/updater/pullio
sudo ln -s $HOME/docker/HOST/updater/pullio /usr/local/bin/pullio


echo "________________________________________________"
echo "                                                " 
echo "       Install Docker and Docker Compose        "
echo "________________________________________________"
sudo pamac install --no-confirm docker docker-compose
# Docker official rootless script is not installed with docker and only available in the Arch User Repository (AUR) thus installed via Pamac.
sudo pamac install --no-confirm docker-rootless-extras-bin

# Required steps before running docker rootless setup tool (see docker documentation)
sudo touch /etc/subuid
sudo touch /etc/subgid
echo "${USER}:100000:65536" | sudo tee -a /etc/subuid
echo "${USER}:100000:65536" | sudo tee -a /etc/subgid
systemctl --user enable --now docker.socket
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

# Run docker rootless setup tool
dockerd-rootless-setuptool.sh install

# enable start at boot and start docker
systemctl --user enable docker
systemctl --user start docker
sudo loginctl enable-linger $(whoami)


echo "_____________________________________________________________"
echo "                     SENDING EMAILS                          "
echo "       allow system to send email notifications              " 
echo "_____________________________________________________________"
# Configure smtp according to Arch wiki
sudo pamac install --no-confirm msmtp
sudo pamac install --no-confirm s-nail
# link sendmail to msmtp
sudo ln -s /usr/bin/msmtp /usr/bin/sendmail
sudo ln -s /usr/bin/msmtp /usr/sbin/sendmail
# set msmtp as mta
echo "set mta=/usr/bin/msmtp" | sudo tee -a /etc/mail.rc
echo "---------------------------------------"
echo "                                                             "
echo "To receive important server notifications, please enter your main/default emailaddress that should receive notifications:"
echo "                                                             "
read -p 'Enter email address to receive server notifications:' DEFAULTEMAIL
sudo sed -i -e "s#default:myemail@address.com#default:$DEFAULTEMAIL#g" /etc/aliases
## Get config file
sudo wget -O /etc/msmtprc https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/system/etc/msmtprc
# set SMTP server
echo "                                                             "
echo "---------------------------------------"
echo "                                                             "
echo "Would you like to configure sending email now? You need to have an smtp provider account correctly configured with your domain" 
read -p "Have you done that and do you have your smtp credentials at hand? (y/n)" answer
case ${answer:0:1} in
    y|Y )
    read -p "Enter SMTP server address (or hit ENTER for default: mail.smtp2go.com):" SMTPSERVER
    SMTPSERVER="${SMTPSERVER:=mail.smtp2go.com}"
    read -p "Enter SMTP server port (or hit ENTER for default:587):" SMTPPORT
    SMTPPORT="${SMTPPORT:=587}"
    read -p 'Enter SMTP username: ' SMTPUSER
    read -p 'Enter password: ' SMTPPASS
    read -p 'Enter the from emailaddress that will be shown as sender, for example username@yourdomain.com: ' FROMADDRESS
    sudo sed -i -e "s#mail.smtp2go.com#$SMTPSERVER#g" /etc/msmtprc
    sudo sed -i -e "s#587#$SMTPPORT#g" /etc/msmtprc
    sudo sed -i -e "s#SMTPUSER#$SMTPUSER#g" /etc/msmtprc
    sudo sed -i -e "s#SMTPPASS#$SMTPPASS#g" /etc/msmtprc
    sudo sed -i -e "s#FROMADDRESS#$FROMADDRESS#g" /etc/msmtprc
    echo "Done, now sending you a test email...." 
    echo "Hello, this is a confirmation from your server, your smtp configuration was successful!" | msmtp -a default $DEFAULTEMAIL
    echo "Email sent!" 
    echo "if an error appeared above, the email has not been sent and you made an error or did not configure your domain and smtp provider" 
    ;;
    * )
        echo "Not configuring SMTP. Please manually enter your SMTP provider details in file /etc/msmprc.." 
    ;;
esac


echo "______________________________________________________"
echo "           OPTIONAL TOOLS OR CONFIGURATIONS           "
echo "______________________________________________________"
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
        sudo pamac install --no-confirm snapper-gui
        # Get snapper default template
        sudo wget -O /etc/snapper/config-templates/default https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/snapraid/snapper/default
        # get SnapRAID config
        sudo wget -O $HOME/docker/HOST/snapraid/snapraid.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/snapraid/snapraid.conf
        sudo ln -s $HOME/docker/HOST/snapraid/snapraid.conf /etc/snapraid.conf
        # DONE !
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

echo "-------------------------------------------------------------------------------------------"
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
echo "Download recommended/best-practices configuration for QBittorrent: to download media, torrents? (recommended)" 
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


echo "--------------------------------------------------------------------------------------------------------------"
echo "Get the PIA VPN script to auto-update Qbittorrent portforwarding? (recommended if you will use PIA VPN for downloads)" 
read -p "y or n ?" answer
case ${answer:0:1} in
    y|Y )
        echo " PIA VPN script to auto-update Qbittorrent  "
        echo "--------------------------------------------"
        mkdir -p HOME/docker/HOST/vpn-proxy/pia-shared
        wget -O $HOME/docker/HOST/vpn-proxy/pia-shared/updateport-qbittorrent.sh https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/vpn-proxy/pia-shared/updateport-qbittorrent.sh
    ;;
    * )
        echo "SKIPPED getting PIA VPN script for auto-updating QB portforwarding.."
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
