# STEP 2: A Modern Homeserver _filesystem_

# SYNOPSIS: [Filesystem explained](https://github.com/zilexa/Homeserver/master/filesystem/FILESYSTEM-EXPLAINED.md)
_Read the Synopsis before continuing with this guide, to understand what you are about to do._

## Requirements: 
1. The OS disk should be BtrFS: [OS Installation](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script/tree/master/OS-installation) shows how to do that.
2. Your system root folder `/` and `/home` folder should be root subvolumes. This is common practice for Ubuntu (Budgie) when you installed it on a BtrFS disk. 
3. With BtrFS it is highly recommended & common practice to create nested subvolumes for systemfolders `/tmp`  and `$HOME/.cache`. Note the [Ubuntu Budgie Post Install Script](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script) does that automatically but you can do it yourself easily, the required actions are detailed in that script. 
4. Install mergerFS: 
```
sudo apt -y install mergerfs
wget https://github.com/trapexit/mergerfs/releases/download/2.32.2/mergerfs_2.32.2.ubuntu-focal_amd64.deb
sudo apt -y install ./mergerfs*.deb
rm mergerfs*.deb
```

&nbsp;

--> If you prefer Raid1, follow those steps and in step 3 notice steps marked "_Exception `Raid1`_" or "_Exception `Raid1` + SSD Cache_". Otherwise ignore those steps. 



### Step 1A: Identify your disks
Note this will delete your data. To convert EXT4 disks without loosing data or add existing BtrFS disks to a filesystem, Google. 
1. unmount all the drives you are going to format: for each disk `sudo umount /media/(diskname)` or use the Disks utility via Budgie menu and hit the stop button for each disk. 
2. list the disk devices: `sudo fdisk -l` you will need the paths of each disks (for example /dev/sda, /dev/sdb, /dev/sdc). 
3. Decide the purpose of each disk and their corresponding label, make notes (`data1`, `data2` etc. `backup1`, `parity1`). 
4. In the next steps, know `-L name` is how you label your disks. 

### STEP 1B: Create the permanent mount points
1. Create mountpoint for the OS disk filesystem root, to be used on-demand: `sudo mkdir /mnt/system`
2. Create mount point for the pool: `sudo mkdir -p /mnt/pool`
3. For the SSD cache: to be able to unload the cache to the disks, also create a mountpoint excluding your cache`sudo mkdir -p /mnt/pool-nocache`. 
4. Create mount point for every disk at once: `sudo mkdir -p /mnt/disks/{cache,data1,data2,data3,parity1,backup1}` (change to reflect the # of drives you have for data, parity and backup.)

<details>
  <summary>### practical commands you might need before step 2A: wipe the disk, delete partitions</summary>
  
- To wipe the filesystems, run this command per partition (a partition is for example /dev/sda1 on disk /dev/sda): `sudo wipefs --all /dev/sda1`
- To delete the partitions: `sudo fdisk /dev/sda`, now you are in the fdisk tool. Hit `m`. You will see the commands available. Use `p` to show the list of partitions, `d` to delete them one by one, `w` to save changes. Then proceed with step 2A. 
- To list all subvolumes in your whole system: `sudo btrfs subvolume list /` or only of one mounted disk `sudo btrfs subvolume list /mnt/disks/data1`.
- To rename an existing subvolume, after mounting the disk, simply use `mv oldname newname`, feel free to use the full path.
- To delete subvolumes, `sudo btrfs subvolume delete /mnt/disks/data1/subvolname`. 
</details>

### STEP 2A: Create filesystems and root subvolumes
1. For the parity disk(s): Create ext4 filesystem with [snapraid's recommended options](https://sourceforge.net/p/snapraid/discussion/1677233/thread/ecef094f/): `sudo mkfs.ext4 -L parity1  -m 0 -i 67108864 -J size=4 /dev/sdX` _where X is the device disk name, see 1A_.
2. For each data and backup disk: Create btrfs filesystem `sudo mkfs.btrfs -f -L data1 /dev/sdX`.
3. For each data disk: Temporarily mount the disk like this: `sudo mount /dev/sdX /mnt/disks/data1`.
4. For each data disk: Create a root subvolume like this: `sudo btrfs subvolume create /mnt/disks/data1/data`.  

<details>
  <summary>### STEP 2B For Raid1 (click to expand)</summary>

1. Create 1 filesystem for all data+backup disks:  `sudo mkfs.btrfs -f -L pool –d raid1 /dev/sda /dev/sdb` for each disk device, set label and path accordingly (see output of fdisk).
2. For the backup disk, use the command in 2A. 
3. Do step 3 and 4 from 1C now, but obtaining the path of your array first via `sudo lsblk`. 
4. Modify the script:  
- Line 10-38 (Snapraid install): remove. Line 3-8 (MergerFS install): remove if you will not use an SSD cache with Raid1. 
- Line 49: remove. Line 48: Keep, as this is the path used by scripts and applications. 
- Line 50: Remove parity1 and remove data1-data3 between brackets { } because raid1 appears as a single disk, it will be mounted to `/mnt/pool`.
- _Exception `Raid1` + SSD Cache_: Add `raid1` between brackets { }. You  will mount the filesystem (in step 4) to `mnt/disks/raid1` and the pool stays `/mnt/pool`.
</details>

### Step 3: edit fstab
`sudo nano /etc/fstab` 
Add your disks etc to the file, use [the example fstab](https://github.com/zilexa/Homeserver/blob/master/filesystem/fstab) in this repository as reference. 
_**Example fstab notes:**_
- There is a line for each system subvolume to mount it to a specific location.
- There is a line for each data disk to mount it to a location.
- There are commented-out lines for the `backup1` and `parity1` disks. They might come in handy and it's good for your reference to add their UUIDs. 
- For MergerFS, the 2 mounts contain many arguments, copy paste them completely. 
  - The first should start with the path of your cache SSD and all data disks (or the path of your raid1 pool) seperated with `:`, mounting them to `/mnt/pool`.
  - The second is identical except without the SSD and a different mount path: `/mnt/pool-nocache`. This second pool will only be used to periodically offload data from the SSD to the data disks. 
  - the paths to your ssd and disks should be identical to the mount points of those physical disks, as configured 

<details>
  <summary>fstab RAID1 exceptions (click to expand)</summary> 
- You only need 1 line for datadisks, with the single UUID of the raid1 filesystem and no line for parity.
- RAID1 + SSD cache: you only need the first MergerFS line (`/mnt/pool`), with the SSD path and the Raid1 path (/mnt/disks/raid1). Because /mnt/disks/raid1 is the path for cache unloading.
</details>

_**MergerFS Notes:**_
- The long list of arguments have carefully been chosen for this Tiered Caching setup.
- [The policies are documented here](https://github.com/trapexit/mergerfs#policy-descriptions). No need to change unless you know what you are doing.
- When you copy these lines from the example fstab to your fstab, make sure you use the correct paths of your data disk mounts, each should be declared separately with their UUIDs above the MergerFS lines (mounted first) just like in the example!

## Step 5: Mount the disks and pools!
1. Make sure all disks are unmounted first: `umount /mnt/disks/data1` for all mount points, also old ones you might have in /media.
2. Make sure each mount point is an empty folder after unmounting.
3. Automatically mount everything in fstab via `sudo mount -a`. If there is no output: Congrats!! Almost done!
4. Verify your disks are mounted at the right paths via `sudo lsblk` or `sudo mount -l`. 

The combined data of your data disks should be in /mnt/pool and also (excluding the SSD cache) in /mnt/pool-nocache.

&nbsp;

### Good practices
** SSD with duplicate metadata**
By default BTRFS formats SSDs with single metadata. After reading mailinglists and discussions between devs, the conclusion is it cannot do harm to enable duplicate metadata and it could possibly save you when data becomes corrupted. To convert an existing  btrfs SSD, for example your system disk from single to dup:  \
`sudo mount /mnt/disks/system`  \
`sudo btrfs balance start -mconvert=dup /mnt/disks/system`  \
Just be patient, when done unmount the root filesystem: `sudo umount /mnt/disks/system`  \

**Harddisk power management**\
Some harddisks (Seagate) spindown/power down immediately when there is no activity, even if a standby timout of XX minutes has been set. This will wear out the disk _fast_.\
Via the Disks app, you can check disk properties and power settings. Note a value of 127 is common but also the culprit here. Changing it to 129 allows the standby timout to work:
```
sudo hdparm -S 240 -B 129 /dev/sdX
```
Perform this command for all your disks. Note 240 = standby after 20min, for 30 min timeout, use 241. 



Continue setting up your [Folder Structure](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure) or go back to the main guide. 
