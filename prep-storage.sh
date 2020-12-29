#!/bin/bash
# Storage setup
# install MergerFS
sudo apt -y install mergerfs
wget https://github.com/trapexit/mergerfs/releases/download/2.32.2/mergerfs_2.32.2.ubuntu-focal_amd64.deb
sudo apt -y install ./mergerfs*.deb
rm mergerfs*.deb

# install SnapRAID
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

# install nocache - required to move files from pool to archive with rsync
sudo apt -y install nocache

# Create the required folders to mount the disks and MergerFS pools
sudo mkdir -p /mnt/pool
sudo mkdir -p /mnt/pool-archive
sudo mkdir -p /mnt/disks/{data_Cache,data_TopLeft,data_TopRight,parity_BottomLeft,parity_BottomRight}


# Configure etc/fstab FIRST (open new terminal for the user, pause the current)
read -p "Use the example etc/fstab to add your disk mounts and MergerFS mounts"
x-terminal-emulator -e sudo nano /etc/fstab
