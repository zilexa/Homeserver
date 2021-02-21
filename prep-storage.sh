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

# install nocache - required to move files from pool to archive with rsync
# ---------------
sudo apt -y install nocache

# Create the required folders to mount the disks and MergerFS pools
# ---------------------------
sudo mkdir -p /mnt/pool
sudo mkdir -p /mnt/pool-archive
sudo mkdir -p /mnt/disks/{cache,data1,data2,data3,parity1,backup1}


# BTRFS subvolumes 
# ---------------
# Mount the BTRFS root, required to create a flat btrfs subvolumes hierarchy, easy to understand and maintain on long term.
sudo mkdir /mnt/btrfs-root
sudo mount -o subvolid=5 /dev/nvme0n1p2 /mnt/btrfs-root
# Create subvolume for docker mounts
sudo btrfs subvolume create /mnt/btrfs-root/@docker
# Create subvolume for system snapshots, they will be backupped to the backup1 disk. 
sudo btrfs subvolume create /mnt/btrfs-root/@system-snapshots
Unmount the btrfs-root filesystem
sudo umount /mnt/root
# Note, you should already have a root subvolume @home and nested subvolumes (root)/tmp and @home/asterix/.cache. See: https://github.com/zilexa/UbuntuBudgie-config 

# Docker BTRFS prep
# Temporary mount the docker subvolume, to be able to move the docker files. 
sudo mv $HOME/docker $HOME/docker-old
sudo mkdir $HOME/docker
sudo mount -o subvol=@docker /dev/nvme0n1p2 $HOME/docker

# IF docker was already running, move the files.
sudo nocache rsync -axHAXWES --info=progress2 $HOME/docker-old/ $HOME/docker


# make the docker subvol mount persistent: add a commented line in /etc/fstab, user will need to add the UUID.
echo "# Mount the BTRFS root subvolume @docker" | sudo tee -a /etc/fstab
echo "UUID=!!COPY-PASTE-FROM-ABOVE /home/asterix/docker           btrfs   defaults,noatime,subvol=@docker 0       2" | sudo tee -a /etc/fstab

# Now open fstab for the user to copy paste the UUIDs and mount points for disks and MergerFS
read -p "Use the example etc/fstab to add your disk mounts and MergerFS mounts and your UUIDs"
x-terminal-emulator -e sudo nano /etc/fstab
sudo nano /etc/fstab
