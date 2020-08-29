# Storage setup
# install MergerFS
wget https://github.com/trapexit/mergerfs/releases/download/2.30.0/mergerfs_2.30.0.ubuntu-xenial_amd64.deb
sudo apt -y install ./mergerfs_2.30.0.ubuntu-xenial_amd64.deb
rm mergerfs*.deb

# install SnapRAID
cd
wget https://github.com/amadvance/snapraid/releases/download/v11.3/snapraid-11.3.tar.gz
tar xzvf snapraid-11.3.tar.gz
cd snapraid-11.3/
./configure
make
make check
make install
cd ..
cp ~/snapraid-11.3/snapraid.conf.example /etc/snapraid.conf
cd ..
rm -rf snapraid*
# Get drive IDs
#ls -la /dev/disk/by-id/ | grep part1  | cut -d " " -f 11-20
# get SnapRAID config
sudo wget -P /etc https://raw.githubusercontent.com/zilexa/Mediaserver/master/snapraid.conf
# SnapRAID create path for local content file
mkdir -p /var/snapraid/

# Create the required folders for MergerFS pool
mkdir -p /mnt/archive
mkdir -p /mnt/pool
mkdir -p /mnt/data/cache
mkdir -p /mnt/data/{disk1,disk2}
mkdir -p /mnt/parity/pardisk1

# Configure etc/fstab FIRST (open new terminal for the user, pause the current)
x-terminal-emulator -e sudo nano /etc/fstab
read -p "Add the required content to etc/fstab in a seperate terminal BEFORE continuing, press enter to continue"
