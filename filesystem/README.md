# STEP 3: A Modern Homeserver _filesystem_

# SYNOPSIS: [Filesystem explained](https://github.com/zilexa/Homeserver/blob/master/filesystem/FILESYSTEM-EXPLAINED.md)
_Read the Synopsis before continuing with this guide, to understand what you are about to do._

## Requirements: 
1. The OS disk should be BtrFS, this should be chosen during [OS Installation](https://github.com/zilexa/manjaro-gnome-post-install). 
2. You have ran the prep-docker.sh script and the server tools have been installed. 
3. You have read the synopsis, had a good night rest and are ready to decide which of the 4 options is best for you!

&nbsp;


## General need-to-knows
- In Linux, every piece of hardware has its own path starting with `/dev/...` For example, SATA drives are listed as `/dev/sda/` the next drive `/dev/sdb/` and so on. Partitions will be `/dev/sda1/`, `/dev/sda2/` and so on. Partitions on the next drive will be `dev/sdb1` etc. 
- No partitions are needed, when you have finished this part of the guide, there should not be a `sda1`. That just overcomplicate things. BTRFS uses subvolumes instead.
- To actually use drives, they need to be mounted to a folder you have created, you cannot use the device path `/dev/`. 
- The system file `/etc/fstab` is a register of all your mounts. You can edit this file easily and this repository has a nice example. Follow it!
- `/etc/stab` should not contain `/dev/` paths, instead the disk ID is used. This ID is persistent unless you remove its filesystem.
- The system usually mounts drives by default inside `/media/`, especially USB drives. To permanently mount your drives, we will use `/mnt/` instead. 
- If the drive name, the path to mount to etc are incorrect in /etc/fstab, you will boot into command line and will need to fix it (or comment out) using `sudo nano /etc/fstab`. 

## How to properly list your drives
Besides the Disks app (look it up in your Menu), There are multiple commands allowing you to view your drives and all its details.  \
```
sudo lsblk -f
```
This will give you the most useful and readable overview of disks, partitions, labels, UUID, remaining space. 
Alternatives are `blkid` and `sudo fdisk -l`. That last can be useful to identify drives by size. 

## Step 1: Erase existing filesystems, partitions, create GPT new partition table
The end goal is to have no partitions, single GPT partition table. 
Yes, you can use tools for this. But to ensure your disks start with a fresh, clean partition table without any floating partitions, this is the way to go: 
1. For each disk, wipe all existing filesystems: 
```
sudo wipefs --all /dev/sda
```` 
2.  Alternatively go directly into fdisk to delete existing partitionsand create a GPT partition table. The most important steps below, [full steps in the Arch Wiki](https://wiki.archlinux.org/title/fdisk#Create_a_partition_table_and_partitions). 
   ```
   sudo fdisk /dev/sda
   ```
   - Hit `m` to list commands, `p` to show the list of partitions, `d` to delete them one by one, `w` to save changes.
   - Hit `g` to remove partition table and create a new GPT partition table.
   - Hit `w` to write changes. This is irriversible. 

## Step 2: Create filesystems 
Make sure you have the correct device path for each drive when you use this command. 
Your OS drive should beon an NVME drive (`/dev/nvmen0p1`), easy to identify and keep out of scope. If you followed the hardware recommendation, you only use SATA drives (HDD or SSD) that means the paths will always be like `/dev/sdX`. 
1. Decide the purpose of each of your drives. The following purposes are available: 
    - `data0, data1, data2` etc: drive containing your user and media data. 
    - `backup1, backup2` etc: drive containing backups. 
    - `parity1, parity2` etc: drive for parity, only when using SnapRAID (read the Filesystem Synopsis). 
    - `cache`: only when using MergerFS Tiered Caching. 
2. depending on the filesystem option you have chosen (see Filesystem Synopsis), create the filesystem as follows and replace LABEL for one of the purposes above.
- BTRFS single: 
    ```mkfs.btrfs -L LABEL -d single /dev/sda /dev/sdb /dev/sdc /dev/sdd```
- BTRFS RAID1: 
    ```mkfs.btrfs -L LABEL -d raid1 /dev/sda /dev/sdb /dev/sdc /dev/sdd```
- Create individual filesystems per drive: 
    ```mkfs.btrfs -m dup -L data0 /dev/sda```
- Create filesystem for your SnapRAID drive (should be EXT4 with these options): 
    ```sudo mkfs.ext4 -L parity1  -m 0 -i 67108864 -J size=4 /dev/sda```

## Step 3: Create mountpoints for each drive
Now that each drive has a filesystem (or in case of BTRFS RAID1 is part of a filesytem), we need to create mountpoints (= paths to assign each drive or filesystem to). 
1. Open the folder /mnt in your file manager, right click and open it with root rights.This will give you a nice view of the structure.
2. With the following command, you create multiple folders.   
```
sudo mkdir -p /mnt/disks/{cache,data0,data1,data2,data3,parity1,backup1,backup2}
```
  - Adjust the command to reflect the drives you have/want to assign. For example, remove `cache` if you are not going to use MergerFS with Tiered Caching (read the Filesystem Synopsis). Also if you only have 2 drives for data and 1 for backup, remove the folders you are not going to use.  
3. Now create the datapool folders. These folders will be the actual path to your drive pool.
    ```
    sudo mkdir -p /mnt/pool/Users
    ```
    ```
    sudo mkdir -p /mnt/pool/Media
    ```
4. If you do use a cache drive, also create a folder `sudo mkdir -p /mnt/pool-nocache`. This path will only be used during nightly maintenance to offload the cache drive.
5. Now have a look in your filemanager and delete/create if you missed something.

By temporarily mounting the drives to the mountpoints, you can test if the drive is accessible via that mountpoint. For example: 
`sudo mount /dev/sda /mnt/disks/data0` 
Make sure you eventually unmount everything you mounted manually. 
Also make sure you unmount everything in /media: `sudo umount /media/*`

## Step 4: Physically label your drives!
If a drive stops working, you turn off your system and remove that drive. How will you know which one to remove? You would need to use the `fdisk -l` command to get the actual serial number and read the numbers of each drive. This is a big hassle. Instead, make sure you properly sticker your drives with the label/mountpoint. 

## Step 5: Configure permanent mounting - FSTAB
This is the most important step, do not make errors. .  You can do this easily as follows:  
1. Open 2 command windows: 
2. In the first one, list each UUID per disk: `sudo lsblk -f`
3. In the second one, make a backup of your fstab first via `sudo cp /etc/fstab /etc/fstabbackup`
4. In the second one, open fstab: `sudo nano /etc/fstab` 
5. Make sure you do not mess with the existing lines. Use the [the example fstab](https://github.com/zilexa/Homeserver/blob/master/filesystem/fstab) as reference, copy only the lines you need and adjust the UUID to match your drives.
6. If you use MergerFS, add those lines in addition to the lines for each disk just like in my example. Make sure to comment out the MergerFS lines first. You want to be sure the lines per drive are correct first. 
7. Save the file via CTRL+O and exit via CTRL+X. Now test if your fstab works without errors: `sudo mount -a` 
8. If it says things couldn't be mounted, make sure you unmount anything you mounted manually or anything that was mounted in `/media`. 
9. If successfull, edit the file again and uncomment the mergerfs lines. Test again. 

_If you use MergerFS:_
- The long list of arguments have carefully been chosen for high performance. 
- [The policies are documented here](https://github.com/trapexit/mergerfs#policy-descriptions). No need to change unless you know what you are doing.
- If you use MergerFS [Tiered Caching](https://github.com/zilexa/Homeserver/blob/master/filesystem/FILESYSTEM-EXPLAINED.md#mergerfs-bonus-ssd-tiered-caching), make sure you have 2 lines, one for `/mnt/pool` that includes the cache drive and one for `/mnt/pool-nocache` that only contains the harddisks. Through Scheduling (see Maintenance guide) you can configure offloading your cache drive by copying its contents (of the drive, not the pool) to the `mnt/pool/-nocache`. Your apps, OS should only use `/mnt/pool`. 


## Step 5: Mount the disks and pools!
1. Make sure all disks are unmounted first: `umount /mnt/disks/data1` for all mount points, also old ones you might have in /media.
2. Make sure each mount point is an empty folder after unmounting.
3. Automatically mount everything in fstab via `sudo mount -a`. If there is no output: Congrats!! Almost done!
4. Verify your disks are mounted at the right paths via `sudo lsblk` or `sudo mount -l`. 

The combined data of your data disks should be in /mnt/pool and also (excluding the SSD cache) in /mnt/pool-nocache.

&nbsp;

Continue setting up your [Folder Structure](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure) or go back to the main guide. 
