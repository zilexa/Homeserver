# Guide: A Modern Homeserver _filesystem_ 

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
- The system file `/etc/fstab` is a register of all your mounts. You can edit this file easily, [example here](https://github.com/zilexa/Homeserver/blob/master/filesystem/fstab). Follow it!
- `/etc/stab` should not contain `/dev/` paths, instead the disk ID is used. This ID is persistent unless you remove its filesystem.
- The system usually mounts drives by default inside `/media/`, especially USB drives. To permanently mount your drives, we will use `/mnt/` instead. 
- If the drive name, the path to mount to etc are incorrect in /etc/fstab, you will boot into command line and will need to fix it (or comment out) using `sudo nano /etc/fstab`. Alternatively, you can simply restore since this guide requires you to make a backup. Restoring: `sudo mv /etc/fstabbackup /etc/fstab` and reboot again. 

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

&nbsp;
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

&nbsp;
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

6. By temporarily mounting the drives to the mountpoints, you can test if the drive is accessible via that mountpoint. For example: 
`sudo mount /dev/sda /mnt/disks/data0`Make sure you eventually unmount everything you mounted manually. Also make sure you unmount everything in /media: `sudo umount /media/*`

&nbsp;
## Step 4: Physically label your drives!
If a drive stops working, you turn off your system and remove that drive. How will you know which one to remove? You would need to use the `fdisk -l` command to get the actual serial number and read the numbers of each drive. This is a big hassle. Instead, make sure you properly sticker your drives with the label/mountpoint. 

&nbsp;
## Step 5: Configure drive mountpoints through FSTAB
This step is prone to errors. Prepare first. 

### _Preparation_
1. Make sure all disks are unmounted first: `umount /mnt/disks/data1` for all mount points, also old ones you might have in /media. You cannot mount to non-empty folder.
2. Make sure each mount point (created in Step 3) is an empty folder after unmounting.
3. Open 2 command windows:
  - In the first one, list each UUID per disk: `sudo lsblk -f`
  - In the second one, make a backup of your fstab first via `sudo cp /etc/fstab /etc/fstabbackup`
  - Stay in the second one, open fstab: `sudo nano /etc/fstab`. Whatever you do next, do not mess up the existing lines!

### _Steps to add drives_ 
1. You now want to add "DRIVE MOUNT POINTS". Use that specific section of the [the example fstab](https://github.com/zilexa/Homeserver/blob/master/filesystem/fstab) as reference, copy only the lines you need!
2. After copying the lines make sure you fill in the right UUID, use the first command window to copy/paste the UUID.
3. Save the file via CTRL+O and exit via CTRL+X. Now test if your fstab works without errors: `sudo mount -a`. This will mount everything listed in fstab. If there is no output: Congrats!! Almost done!
4. If it says things couldn't be mounted, edit the file again, fix the errors, repeat step 3.  
5. Verify your disks are mounted at the right paths via `sudo lsblk` or `sudo mount -l`. 

&nbsp;
## Step 6: Create subvolumes
Each filesystem should have at least 1 subvolume. Subvolumes are the special folders of BTRFS that can be snapshotted and securily copied/transmitted to other drives or locations (for backup purposes). This guide assumes 2 types of data:  \

- _Users_
  contains per-user folders, each user folder will contain all data of that user (documents, photos etc). Note that if you have family content such as your photo collection, this can be stored in a family-user account (for example user "Shared"). This way, each user still has their own data but also access to a Shared folder. 
- _Media_
  not user-specific and often generally available such as Downloads; Movies, TV Shows, Music Albums. 

1. decide which of your `data` drives (`data0`, `data1` etc) will contain USER or MEDIA data. 
2. It is highly recommended to not combine them on the same drive. If you have 3 drives and don't believe 1 drive for Users and 1 for Media is enough, use the 3rd drive for both as a sort of overflow. Create 2 subvolumes on that drive.  
3. If you use BTRFS RAID1, you don't create subvolumes per drive, only per filesystem. 
4.  Create a subvolume (needs to be done per filesystem). In this example I use 4 drives, 1 for downloads/media and 3 for user data: 
```sudo btrfs subvolume create /mnt/disks/data0/Media``` 
```sudo btrfs subvolume create /mnt/disks/data1/Users``` 
```sudo btrfs subvolume create /mnt/disks/data2/Users``` 

&nbsp;
## Step 7: Add pools to FSTAB
Now that you have subvolumes, you can mount the subvolumes to the different pools by editing `/etc/fstab` again: 
```
sudo nano /etc/fstab
```
The goal is to have all your data accessible for users and applications or cloud services via `/mnt/pool/Media` and `mnt/pool/Users`, regardless of underlying drives. Also, snapshot/backup folders will not be visible here as you want to isolate those instead of exposing them to users/applications. 

### _Option 1: single drive per datatype or BTRFS1_
If you only have 1 Media drive and 1 Users drive OR if you use a BTRFS1 array, you can mount the drives directly without MergerFS to the respective `/mnt/pool/Media` and `mnt/pool/Users` folders that we created in step 3. 
```
UUID=8e9f178a-e531-40ce-87a9-801aa11aa4ea /mnt/pool/Media btrfs defaults,noatime,compress-force=zstd:2,subvol=Media 0 0
UUID=0187bc8c-4188-4b25-b4d6-46dcd655c3ce /mnt/pool/Users btrfs defaults,noatime,compress-force=zstd:2,subvol=Users 0 0
```
- The `subvol=` option is important here!
- Note`UUID=` is the UUID of the drive, easy to find as it should already be listed in your fstab (see Step 5).
- In case of BTRFS RAID1, just use the UUID of the first drive. 


### _Option 2: multiple drives pooled via MergerFS_
If you have multiple drives that need to be pooled, you merge them via MergerFS. for example:  \
`/mnt/disks/data1/Users` and `/mnt/disks/data2/Users`  \
`/mnt/disks/data0/Media` and `/mnt/disks/data3/Media`  \
To merge/pool the Users drives and the Media drives, you simply add a line in FSTAB for each desired pool, using MergerFS as filesystem: 
```
/mnt/disks/data1/Users:/mnt/disks/data2/Users /mnt/pool/Users fuse.mergerfs ...
/mnt/disks/data0/Media:/mnt/disks/data3/Media /mnt/pool/Media fuse.mergerfs ... 
``` 
1. This is an incomplete example, go to [the example fstab](https://github.com/zilexa/Homeserver/blob/master/filesystem/fstab) and copy the first MergerFS example line into your fstab.
2. Change the paths of your drive to reflect your situation.
3. You can optionally change a few arguments to your desire: 
  - FSNAME: a name to identify your pool for the OS. Not important.
  - MINFREESPACE: when this threshold has been reached, the disk is considered full and depending on the MergerFS policy it will write to the next drive.
  - POLICY: MergerFS will follow a _Least Free Space (LFS)_ policy; filling up disk by disk starting with the first disk. This way, you always know where your data is stored. You can also choose a different policy for example to fill each drive equally by always selecting the drive with the _most free space (MFS)_ and there are lots of other policies. [The policies are documented here](https://github.com/trapexit/mergerfs#policy-descriptions). No need to change unless you know what you are doing.
  - The rest of the long list of arguments have carefully been chosen for high performance while maintaining stability. 


### _Option 3: MergerFS with Tiered Cache_
If you do use MergerFS [Tiered Caching](https://github.com/zilexa/Homeserver/blob/master/filesystem/FILESYSTEM-EXPLAINED.md#mergerfs-bonus-ssd-tiered-caching) do the following: 
1. Same as Option 2 but add `/mnt/disks/cache/Users` and/or `/mnt/disks/cache/Media` as first drive in each MergerFS line. 
2. Add additional MergerFS lines: each MergerFS pool should also have a corresponding "no-cache" pool containing only the harddisks and mounted to `/mnt/pool-nocache/Users` or `/mnt/pool-nocache/Media`. Through Scheduling (see Maintenance guide) you can configure offloading your cache drive by copying its contents (of the drive, not the pool) to the subfolders of `mnt/pool-nocache`. 
3. Realize that all data in `/mnt/pool/no-cache` is also in `/mnt/pool/` since one is a subset of the other. 

#### Why do we mount subvolumes instead of the root of the drive?
--> In /mnt/pool/ you only want to see Users and Media. The Backup Guide will require additional folders in the root of each drive (for snapshots and/or parity). As a best practice, you should only expose folders to users and applications that must be exposed. Exposing your backup/snapshots folder serves no purpose. 

&nbsp;
## Step 8: Fix the personal folder links in $HOME
If you used the Manjaro Gnome Post Install script, your common personal folders (Desktop, Documents, Pictures, Music, Media) are actually links that link to a subvolume `userdata` on your OS drive, visible in `/mnt/disks/systemdrive`. Since you are configuring a server, you probably want to link those $HOME folders to your own user folder within your datapool (`/mnt/pool/Users/MYNAME/` or `/mnt/pool/Users/Shared/`)
```
ln -s /mnt/pool/Users/Shared/Documents $HOME/Documents
ln -s /mnt/pool/Users/Shared/Pictures $HOME/Pictures
ln -s /mnt/pool/Users/Shared/Desktop $HOME/Desktop
ln -s /mnt/pool/Media $HOME/Media
ln -s /mnt/pool/Media/Music $HOME/Music
```
Do not forget to delete the `/mnt/disks/systemdrive/userdata` subvolume, simply by deleting it like a folder.

&nbsp;
Have a look at [Folder Structure Recommendations](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure), follow the tips in the _Data Migration_ to 100% securily copy your data and verify each read & write is correct (using Rsync or BTRFS send/receive). 
If you are going to download stuff, follow the 2 HIGHLY RECOMMENDED actions under Step 3 for your incoming downloads folder. 
