#!/bin/bash
# Storage setup - RUN THIS BEFORE setting up the server
# install MergerFS
# -----------------
sudo apt -y install mergerfs
wget https://github.com/trapexit/mergerfs/releases/download/2.32.2/mergerfs_2.32.2.ubuntu-focal_amd64.deb
sudo apt -y install ./mergerfs*.deb
rm mergerfs*.deb

# install SnapRAID
# ----------------
sudo apt -y install gcc git make
wget https://github.com/amadvance/snapraid/releases/download/v11.5/snapraid-11.5.tar.gz
tar xzvf snapraid*.tar.gz
cd snapraid-11.5/
./configure
make
make check
make install
cd $HOME/Downloads
sudo cp snapraid-11.5/snapraid.conf.example /etc/snapraid.conf.example
rm -rf snapraid*
# Get drive IDs
#ls -la /dev/disk/by-id/ | grep part1  | cut -d " " -f 11-20
# get SnapRAID config
sudo wget -P /etc https://raw.githubusercontent.com/zilexa/Homeserver/master/snapraid/snapraid.conf
# SnapRAID create path for local content file
sudo mkdir -p /var/snapraid/

# Get snapraid-btrfs script and make it executable
sudo wget -P /etc https://raw.githubusercontent.com/automorphism88/snapraid-btrfs/master/snapraid-btrfs
sudo chmod +x /etc/snapraid-btrfs

# Install snapper, required for snapraid-btrfs 
echo 'deb http://download.opensuse.org/repositories/filesystems:/snapper/xUbuntu_20.10/ /' | sudo tee /etc/apt/sources.list.d/filesystems:snapper.list
curl -fsSL https://download.opensuse.org/repositories/filesystems:snapper/xUbuntu_20.10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/filesystems_snapper.gpg > /dev/null
sudo apt -y update
sudo apt -y install snapper

# install nocache - required to move files from pool to archive with rsync
# ---------------
sudo apt -y install nocache

# Create the required folders to mount the disks and MergerFS pools
# !!! CHANGE THESE LINES!!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!
# UPDATE: commented out since user needs to create root subvolumes before mounting. Described in step1. 
# ---------------------------
#sudo mkdir -p /mnt/pool
#sudo mkdir -p /mnt/pool-archive #Comment-out/skip if no SSD cache
#sudo mkdir -p /mnt/disks/{cache,data1,data2,data3,parity1,backup1}  #add/remove according to your number of disks


# BTRFS nested subvolumes (common practice to exclude from snapshots/backups)
# ================
# Create nested subvolume for /tmp
cd /
sudo mv /tmp /tmpold
sudo btrfs subvolume create tmp
sudo chmod 1777 /tmp
sudo mv /tmpold/* /tmp
sudo rm -r /tmpold
# Create nested subvolume for $HOME/.cache
cd $HOME
mv ~/.cache ~/.cacheold
btrfs subvolume create .cache
mv .cacheold/* .cache
rm -r .cacheold/

#BTRFS root subvolumes (for docker and snapshots)
=======================
# Mount the BTRFS root, required to create a flat btrfs subvolumes hierarchy, easy to understand and maintain on long term.
sudo mkdir /mnt/btrfs-root
sudo mount -o subvolid=5 /dev/nvme0n1p2 /mnt/btrfs-root
# Create subvolume for docker mounts
sudo btrfs subvolume create /mnt/btrfs-root/@docker
# Create subvolume for system snapshots, they will be backupped to the backup1 disk. 
sudo btrfs subvolume create /mnt/btrfs-root/@system-snapshots
Unmount the btrfs-root filesystem
sudo umount /mnt/root

# Note, its highly recommended to have a root subvolume @home to be able to snapshot/backup them seperately.
# See: https://github.com/zilexa/UbuntuBudgie-post-install

# Docker BTRFS prep
# Temporary mount the docker subvolume, to be able to move the docker files. 
sudo mv $HOME/docker $HOME/docker-old
sudo mkdir $HOME/docker
sudo mount -o subvol=@docker /dev/nvme0n1p2 $HOME/docker

# IF docker was already running, move the files.
sudo nocache rsync -axHAXWES --info=progress2 $HOME/docker-old/ $HOME/docker

# make the docker subvol mount persistent: add a commented line in /etc/fstab, user will need to add the UUID.
echo "# Mount the BTRFS root subvolume @docker" | sudo tee -a /etc/fstab
echo "UUID=!ADD YOUR OS/SYSTEM SSD UUID HERE (just COPY from above)! /home/asterix/docker  btrfs   defaults,noatime,compress=lzo,subvol=@docker 0       2" | sudo tee -a /etc/fstab

# Manual actions by user: 
#1. in fstab copy system disk UUID shown in fstab to docker mount
#2. Find UUIDs of other disks
#3. Add disks to fstab according to the example fstab file
echo "==========================================================================================================="
echo "The script is now done."
echo "Before rebooting, you need to (Task 1) add the UUID of your OS disk to the line that was just added to your mountfile /etc/fstab" 
echo "While doing that, you can also (Task 2) add the mount points of all your disks according to the fstab example from the documentation" 
echo "-----------------------------------------------------------------------------------------------------------"
echo "To do both tasks manually in 1 single file edit (easier), just continue this script. Or do it later like this:" 
echo "for Task1: run 'sudo nano /etc/fstab' and switch the text in CAPS with the UUID above it"
echo "for Task2: run 'sudo blkid' to get UUIDS/disks and in a 2nd window, 'sudo nano /etc/fstab'"
echo "Use the example file, add the lines to your fstab with your own UUIDs"
echo "==========================================================================================================="
read -p "Read between the lines then HIT CTRL+C to stop the script here or hit ENTER to do it now..."
# run command to find UUIDs, open fstab in seperate window 
sudo blkid
x-terminal-emulator -e sudo nano /etc/fstab
echo "============================================================================================"
echo " UUIDs will be printed!"
echo "2nd window openened!" Enter password in the 2nd window to open the file."
echo "CTRL+O to save changes, CTRL+X to exit the file." 
echo "--------------------------------------------------------------------------------------------"
echo "Edit the bottom line with the UUID you see at the top of the file" 
echo "Then add lines according to the EXAMPLE FSTAB and your disks UUIDs printed here"
read -p "Hit Enter in this screen to continue."
echo "============================================================================================" 
echo "To mount everything now, run 'sudo mount -a'" 
echo "============================================================================================"
echo "Note, if you did not modify line 38-40 of this script or created the folders for mounting yourself,"
echo "you need to do that first: 'sudo mkdir /mnt/pool', 'sudo mkdir /mnt/disks/data1' etc"  
